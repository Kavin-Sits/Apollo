//
//  AppSession.swift
//  Apollo
//

import Foundation
import UIKit

extension Notification.Name {
    static let profilePhotoDidChange = Notification.Name("apollo.profilePhotoDidChange")
    static let interestsDidChange = Notification.Name("apollo.interestsDidChange")
    static let recommendationSignalsDidChange = Notification.Name("apollo.recommendationSignalsDidChange")
}

enum AppSession {
    static let guestUserID = "guest@apollo.local"

    private static let guestModeKey = "apollo.guestMode"
    private static let interestsKeyPrefix = "apollo.interests."
    private static let seenArticlesKeyPrefix = "apollo.seenArticles."
    private static let likedArticlesKeyPrefix = "apollo.likedArticles."
    private static let savedArticlesKeyPrefix = "apollo.savedArticles."
    private static let locationKeyPrefix = "apollo.location."
    private static let occupationKeyPrefix = "apollo.occupation."
    private static let profilePhotoKeyPrefix = "apollo.profilePhoto."
    private static let recommendationProfileKeyPrefix = "apollo.recommendationProfile."
    private static let topicPreferencesKeyPrefix = "apollo.topicPreferences."

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
                return UserDefaults.standard.stringArray(forKey: interestsStorageKey) ?? []
            }
        }

        return UserDefaults.standard.stringArray(forKey: interestsStorageKey) ?? []
    }

    static func saveInterests(_ interests: [String], for userID: String? = nil) async throws {
        let normalized = Array(Set(interests)).sorted()

        if hasAuthenticatedUser {
            try await SupabaseService.shared.replaceInterests(normalized)
        } else {
            UserDefaults.standard.set(normalized, forKey: interestsStorageKey)
        }

        NotificationCenter.default.post(name: .interestsDidChange, object: nil)
    }

    static func loadSeenArticleIDs() async -> Set<String> {
        let localSeen = Set(UserDefaults.standard.stringArray(forKey: seenArticlesStorageKey) ?? [])

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

    static func saveArticle(_ article: Article, completion: @escaping (Bool) -> Void = { _ in }) {
        if hasAuthenticatedUser {
            Task {
                do {
                    try await SupabaseService.shared.saveArticle(article)
                    try? await SupabaseService.shared.recordArticleFeedback(articleURL: article.url, actions: [.saved])
                    await persistRecommendationFeedback(for: article, kind: .saved)
                    completion(true)
                } catch {
                    saveLocalArticle(
                        SavedArticle(
                            title: article.title,
                            url: article.url,
                            description: article.description,
                            urlToImage: article.urlToImage
                        )
                    )
                    await persistRecommendationFeedback(for: article, kind: .saved)
                    completion(false)
                }
            }
            return
        }

        saveLocalArticle(
            SavedArticle(
                title: article.title,
                url: article.url,
                description: article.description,
                urlToImage: article.urlToImage
            )
        )
        Task {
            await persistRecommendationFeedback(for: article, kind: .saved)
        }
        completion(true)
    }

    static func loadSavedArticles() async -> [SavedArticle] {
        if hasAuthenticatedUser {
            do {
                return try await SupabaseService.shared.fetchSavedArticles()
            } catch {
                return loadLocalSavedArticles()
            }
        }

        return loadLocalSavedArticles()
    }

    static func saveLocation(_ location: String) {
        guard let userID = currentUserID else { return }

        if hasAuthenticatedUser {
            Task {
                try? await SupabaseService.shared.upsertProfile(location: location)
                NotificationCenter.default.post(name: .recommendationSignalsDidChange, object: nil)
            }
        } else {
            UserDefaults.standard.set(location, forKey: locationKeyPrefix + userID)
            NotificationCenter.default.post(name: .recommendationSignalsDidChange, object: nil)
        }
    }

    static func saveOccupation(_ occupation: String) {
        guard let userID = currentUserID else { return }

        if hasAuthenticatedUser {
            Task {
                try? await SupabaseService.shared.upsertProfile(occupation: occupation)
                NotificationCenter.default.post(name: .recommendationSignalsDidChange, object: nil)
            }
        } else {
            UserDefaults.standard.set(occupation, forKey: occupationKeyPrefix + userID)
            NotificationCenter.default.post(name: .recommendationSignalsDidChange, object: nil)
        }
    }

    static func loadProfile() async -> SupabaseProfile? {
        if hasAuthenticatedUser {
            return try? await SupabaseService.shared.fetchProfile()
        }

        guard let userID = currentUserID else { return nil }

        return SupabaseProfile(
            id: userID,
            email: userID,
            fullName: nil,
            dateOfBirth: nil,
            location: UserDefaults.standard.string(forKey: locationKeyPrefix + userID),
            occupation: UserDefaults.standard.string(forKey: occupationKeyPrefix + userID),
            profilePhotoURL: nil
        )
    }

    static func loadRecommendationState(
        interests: [String]? = nil,
        profile: SupabaseProfile? = nil
    ) async -> RecommendationState {
        let loadedInterests = if let interests {
            interests
        } else {
            await loadInterests()
        }
        let loadedProfile = if let profile {
            profile
        } else {
            await loadProfile()
        }
        let cachedProfile = loadLocalRecommendationProfile()
        let cachedTopics = loadLocalTopicPreferences()

        if hasAuthenticatedUser {
            do {
                let remoteProfile = try await SupabaseService.shared.fetchRecommendationProfile()
                let remoteTopics = try await SupabaseService.shared.fetchTopicPreferences()
                let state = RecommendationState(profile: remoteProfile ?? cachedProfile, topicPreferences: remoteTopics.isEmpty ? cachedTopics : remoteTopics)

                if state.profile == nil && state.topicPreferences.isEmpty,
                   let authUserID = SupabaseService.shared.currentUserID {
                    let backfilled = RecommendationService.shared.buildBackfilledState(
                        userID: authUserID,
                        profile: loadedProfile,
                        interests: loadedInterests,
                        savedArticles: await loadSavedArticles()
                    )
                    await saveRecommendationState(backfilled)
                    return backfilled
                }

                let normalizedState = RecommendationState(profile: state.profile, topicPreferences: state.topicPreferences)
                cacheRecommendationStateLocally(normalizedState)
                return normalizedState
            } catch {
                let fallback = RecommendationState(profile: cachedProfile, topicPreferences: cachedTopics)
                if fallback.profile == nil && fallback.topicPreferences.isEmpty,
                   let authUserID = SupabaseService.shared.currentUserID {
                    let backfilled = RecommendationService.shared.buildBackfilledState(
                        userID: authUserID,
                        profile: loadedProfile,
                        interests: loadedInterests,
                        savedArticles: await loadSavedArticles()
                    )
                    cacheRecommendationStateLocally(backfilled)
                    return backfilled
                }
                return fallback
            }
        }

        if cachedProfile != nil || !cachedTopics.isEmpty {
            return RecommendationState(profile: cachedProfile, topicPreferences: cachedTopics)
        }

        let backfilled = RecommendationService.shared.buildBackfilledState(
            userID: currentUserID ?? guestUserID,
            profile: loadedProfile,
            interests: loadedInterests,
            savedArticles: await loadSavedArticles()
        )
        cacheRecommendationStateLocally(backfilled)
        return backfilled
    }

    static func saveRecommendationState(_ state: RecommendationState) async {
        cacheRecommendationStateLocally(state)

        guard hasAuthenticatedUser else {
            return
        }

        do {
            try await SupabaseService.shared.upsertRecommendationState(state)
        } catch {
            print("Failed to save recommendation state: \(error.localizedDescription)")
        }
    }

    @discardableResult
    static func markDismissed(
        article: Article,
        currentState: RecommendationState? = nil,
        profile: SupabaseProfile? = nil
    ) -> RecommendationState? {
        recordFeedback(for: article, actions: [.disliked, .seen])
        updateLocalStringArray(forKey: seenArticlesStorageKey, appending: article.id)
        return applyRecommendationFeedback(for: article, kind: .disliked, currentState: currentState, profile: profile)
    }

    @discardableResult
    static func markLiked(
        article: Article,
        currentState: RecommendationState? = nil,
        profile: SupabaseProfile? = nil
    ) -> RecommendationState? {
        recordFeedback(for: article, actions: [.liked, .seen])
        updateLocalStringArray(forKey: likedArticlesStorageKey, appending: article.id)
        updateLocalStringArray(forKey: seenArticlesStorageKey, appending: article.id)
        return applyRecommendationFeedback(for: article, kind: .liked, currentState: currentState, profile: profile)
    }

    @discardableResult
    static func markOpened(
        article: Article,
        currentState: RecommendationState? = nil,
        profile: SupabaseProfile? = nil
    ) -> RecommendationState? {
        recordFeedback(for: article, actions: [.opened])
        updateLocalStringArray(forKey: seenArticlesStorageKey, appending: article.id)
        return applyRecommendationFeedback(for: article, kind: .opened, currentState: currentState, profile: profile)
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

    private static func saveLocalArticle(_ article: SavedArticle) {
        var articles = loadLocalSavedArticles()
        articles.removeAll { $0.url == article.url }
        articles.insert(article, at: 0)

        guard let encoded = try? JSONEncoder().encode(articles) else {
            return
        }

        UserDefaults.standard.set(encoded, forKey: savedArticlesStorageKey)
    }

    private static func loadLocalSavedArticles() -> [SavedArticle] {
        guard let data = UserDefaults.standard.data(forKey: savedArticlesStorageKey),
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

    private static var storageUserKey: String {
        currentUserID ?? guestUserID
    }

    private static var interestsStorageKey: String {
        interestsKeyPrefix + storageUserKey
    }

    private static var seenArticlesStorageKey: String {
        seenArticlesKeyPrefix + storageUserKey
    }

    private static var likedArticlesStorageKey: String {
        likedArticlesKeyPrefix + storageUserKey
    }

    private static var savedArticlesStorageKey: String {
        savedArticlesKeyPrefix + storageUserKey
    }

    private static var occupationStorageKey: String {
        occupationKeyPrefix + storageUserKey
    }

    private static var recommendationProfileStorageKey: String {
        recommendationProfileKeyPrefix + storageUserKey
    }

    private static var topicPreferencesStorageKey: String {
        topicPreferencesKeyPrefix + storageUserKey
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
            do {
                try await SupabaseService.shared.recordArticleFeedback(articleURL: article.url, actions: actions)
            } catch {
                let actionSummary = actions.map(\.rawValue).joined(separator: ",")
                print("Failed to record article feedback (\(actionSummary)): \(error.localizedDescription)")
            }
        }
    }

    private static func applyRecommendationFeedback(
        for article: Article,
        kind: RecommendationFeedbackKind,
        currentState: RecommendationState?,
        profile: SupabaseProfile?
    ) -> RecommendationState? {
        if let currentState {
            let update = RecommendationService.shared.applyFeedback(
                for: article,
                kind: kind,
                currentState: currentState,
                profile: profile
            )
            let nextState = RecommendationState(profile: update.profile, topicPreferences: update.topicPreferences)
            cacheRecommendationStateLocally(nextState)
            Task {
                await saveRecommendationState(nextState)
            }
            return nextState
        }

        Task {
            await persistRecommendationFeedback(for: article, kind: kind)
        }
        return nil
    }

    private static func persistRecommendationFeedback(for article: Article, kind: RecommendationFeedbackKind) async {
        let profile = await loadProfile()
        let currentState = await loadRecommendationState(profile: profile)
        let update = RecommendationService.shared.applyFeedback(
            for: article,
            kind: kind,
            currentState: currentState,
            profile: profile
        )
        await saveRecommendationState(
            RecommendationState(
                profile: update.profile,
                topicPreferences: update.topicPreferences
            )
        )
    }

    private static func loadLocalRecommendationProfile() -> RecommendationProfile? {
        guard let data = UserDefaults.standard.data(forKey: recommendationProfileStorageKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(RecommendationProfile.self, from: data)
    }

    private static func loadLocalTopicPreferences() -> [TopicPreference] {
        guard let data = UserDefaults.standard.data(forKey: topicPreferencesStorageKey) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([TopicPreference].self, from: data)) ?? []
    }

    private static func cacheRecommendationStateLocally(_ state: RecommendationState) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let profile = state.profile, let encodedProfile = try? encoder.encode(profile) {
            UserDefaults.standard.set(encodedProfile, forKey: recommendationProfileStorageKey)
        }

        if let encodedTopics = try? encoder.encode(state.topicPreferences) {
            UserDefaults.standard.set(encodedTopics, forKey: topicPreferencesStorageKey)
        }
    }
}
