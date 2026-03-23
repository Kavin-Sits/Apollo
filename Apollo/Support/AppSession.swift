//
//  AppSession.swift
//  Apollo
//

import Foundation
import UIKit

extension Notification.Name {
    static let profilePhotoDidChange = Notification.Name("apollo.profilePhotoDidChange")
}

enum AppSession {
    static let guestUserID = "guest@apollo.local"

    private static let guestModeKey = "apollo.guestMode"
    private static let guestInterestsKey = "apollo.guestInterests"
    private static let guestSeenArticlesKey = "apollo.guestSeenArticles"
    private static let guestLikedArticlesKey = "apollo.guestLikedArticles"
    private static let guestSavedArticlesKey = "apollo.guestSavedArticles"
    private static let locationKeyPrefix = "apollo.location."
    private static let profilePhotoKeyPrefix = "apollo.profilePhoto."

    static var isGuestModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: guestModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: guestModeKey) }
    }

    static var currentUserID: String? {
        SupabaseService.shared.currentUserEmail ?? (isGuestModeEnabled ? guestUserID : nil)
    }

    static var hasAuthenticatedUser: Bool {
        SupabaseService.shared.isAuthenticated
    }

    static func startGuestSession() {
        isGuestModeEnabled = true
    }

    static func endGuestSession() {
        isGuestModeEnabled = false
    }

    static func signUp(
        email: String,
        password: String,
        fullName: String,
        dateOfBirth: String,
        location: String,
        occupation: String,
        interests: [String]
    ) async throws {
        _ = try await SupabaseService.shared.signUp(email: email, password: password)
        _ = try await SupabaseService.shared.signIn(email: email, password: password)
        try await SupabaseService.shared.upsertProfile(
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            location: location,
            occupation: occupation
        )
        try await SupabaseService.shared.replaceInterests(interests)
    }

    static func signIn(email: String, password: String) async throws {
        _ = try await SupabaseService.shared.signIn(email: email, password: password)
        isGuestModeEnabled = false
        try await ensureProfileExists()
    }

    static func signOut() async {
        await SupabaseService.shared.signOut()
        isGuestModeEnabled = false
    }

    static func resetPassword(email: String) async throws {
        try await SupabaseService.shared.resetPassword(email: email)
    }

    static func updatePassword(_ password: String) async throws {
        try await SupabaseService.shared.updatePassword(password)
    }

    static func deleteAccount() async throws {
        throw SupabaseServiceError.unsupported("Supabase account deletion needs a secure server-side function. We should add that as a follow-up.")
    }

    static func loadInterests() async -> [String] {
        if hasAuthenticatedUser {
            do {
                return try await SupabaseService.shared.fetchInterests()
            } catch {
                return UserDefaults.standard.stringArray(forKey: guestInterestsKey) ?? []
            }
        }

        return UserDefaults.standard.stringArray(forKey: guestInterestsKey) ?? []
    }

    static func saveInterests(_ interests: [String], for userID: String? = nil) async throws {
        let normalized = Array(Set(interests)).sorted()

        if hasAuthenticatedUser {
            try await SupabaseService.shared.replaceInterests(normalized)
        } else {
            UserDefaults.standard.set(normalized, forKey: guestInterestsKey)
        }
    }

    static func loadSeenArticleIDs() async -> Set<String> {
        let localSeen = Set(UserDefaults.standard.stringArray(forKey: guestSeenArticlesKey) ?? [])

        guard hasAuthenticatedUser else {
            return localSeen
        }

        do {
            let remoteSeen = try await SupabaseService.shared.fetchArticleFeedbackURLs(for: [.seen, .opened, .liked, .disliked, .saved])
            return localSeen.union(remoteSeen)
        } catch {
            return localSeen
        }
    }

    static func markDismissed(article: Article) {
        recordFeedback(for: article, actions: [.disliked, .seen])
        updateLocalStringArray(forKey: guestSeenArticlesKey, appending: article.id)
    }

    static func markLiked(article: Article) {
        recordFeedback(for: article, actions: [.liked, .seen])
        updateLocalStringArray(forKey: guestLikedArticlesKey, appending: article.id)
        updateLocalStringArray(forKey: guestSeenArticlesKey, appending: article.id)
    }

    static func markOpened(article: Article) {
        recordFeedback(for: article, actions: [.opened])
        updateLocalStringArray(forKey: guestSeenArticlesKey, appending: article.id)
    }

    static func saveArticle(_ article: Article, completion: @escaping (Bool) -> Void = { _ in }) {
        if hasAuthenticatedUser {
            Task {
                do {
                    try await SupabaseService.shared.saveArticle(article)
                    try? await SupabaseService.shared.recordArticleFeedback(articleURL: article.url, action: .saved)
                    completion(true)
                } catch {
                    saveGuestArticle(
                        SavedArticle(
                            title: article.title,
                            url: article.url,
                            description: article.description,
                            urlToImage: article.urlToImage
                        )
                    )
                    completion(false)
                }
            }
            return
        }

        saveGuestArticle(
            SavedArticle(
                title: article.title,
                url: article.url,
                description: article.description,
                urlToImage: article.urlToImage
            )
        )
        completion(true)
    }

    static func loadSavedArticles() async -> [SavedArticle] {
        if hasAuthenticatedUser {
            do {
                return try await SupabaseService.shared.fetchSavedArticles()
            } catch {
                return loadGuestSavedArticles()
            }
        }

        return loadGuestSavedArticles()
    }

    static func saveLocation(_ location: String) {
        guard let userID = currentUserID else { return }

        if hasAuthenticatedUser {
            Task {
                try? await SupabaseService.shared.upsertProfile(location: location)
            }
        } else {
            UserDefaults.standard.set(location, forKey: locationKeyPrefix + userID)
        }
    }

    @discardableResult
    static func saveProfilePhoto(_ image: UIImage) -> Bool {
        guard let userID = currentUserID,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return false
        }

        UserDefaults.standard.set(data, forKey: profilePhotoKeyPrefix + userID)
        NotificationCenter.default.post(name: .profilePhotoDidChange, object: nil)
        return true
    }

    static func loadProfilePhoto() -> UIImage? {
        guard let userID = currentUserID,
              let data = UserDefaults.standard.data(forKey: profilePhotoKeyPrefix + userID) else {
            return nil
        }

        return UIImage(data: data)
    }

    static func loadProfilePhotoURL() async -> String? {
        guard hasAuthenticatedUser else {
            return nil
        }

        return try? await SupabaseService.shared.fetchProfile()?.profilePhotoURL
    }

    static func saveProfilePhotoURL(_ url: String) {
        guard hasAuthenticatedUser else { return }
        Task {
            try? await SupabaseService.shared.upsertProfile(profilePhotoURL: url)
        }
    }

    private static func saveGuestArticle(_ article: SavedArticle) {
        var articles = loadGuestSavedArticles()
        articles.removeAll { $0.url == article.url }
        articles.insert(article, at: 0)

        guard let encoded = try? JSONEncoder().encode(articles) else {
            return
        }

        UserDefaults.standard.set(encoded, forKey: guestSavedArticlesKey)
    }

    private static func loadGuestSavedArticles() -> [SavedArticle] {
        guard let data = UserDefaults.standard.data(forKey: guestSavedArticlesKey),
              let articles = try? JSONDecoder().decode([SavedArticle].self, from: data) else {
            return []
        }

        return articles
    }

    private static func updateLocalStringArray(forKey key: String, appending value: String) {
        var values = UserDefaults.standard.stringArray(forKey: key) ?? []
        if !values.contains(value) {
            values.append(value)
        }
        UserDefaults.standard.set(values, forKey: key)
    }

    private static func ensureProfileExists() async throws {
        guard hasAuthenticatedUser else {
            return
        }

        if try await SupabaseService.shared.fetchProfile() == nil {
            try await SupabaseService.shared.upsertProfile()
        }
    }

    private static func recordFeedback(for article: Article, actions: [ArticleFeedbackAction]) {
        guard hasAuthenticatedUser else {
            return
        }

        Task {
            for action in actions {
                do {
                    try await SupabaseService.shared.recordArticleFeedback(articleURL: article.url, action: action)
                } catch {
                    print("Failed to record article feedback (\(action.rawValue)): \(error.localizedDescription)")
                }
            }
        }
    }
}
