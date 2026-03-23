//
//  AppSession.swift
//  Apollo
//

import Foundation
import FirebaseAuth
import UIKit

enum AppSession {
    static let guestUserID = "guest@apollo.local"

    private static let guestModeKey = "apollo.guestMode"
    private static let localUserIDKey = "apollo.localUserID"
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
        Auth.auth().currentUser?.email ??
        UserDefaults.standard.string(forKey: localUserIDKey) ??
        (isGuestModeEnabled ? guestUserID : nil)
    }

    static var hasAuthenticatedUser: Bool {
        Auth.auth().currentUser != nil
    }

    static func startGuestSession() {
        isGuestModeEnabled = true
        UserDefaults.standard.removeObject(forKey: localUserIDKey)
    }

    static func endGuestSession() {
        isGuestModeEnabled = false
    }

    static func startLocalSession(email: String) {
        isGuestModeEnabled = false
        UserDefaults.standard.set(email, forKey: localUserIDKey)
    }

    static func loadInterests() async -> [String] {
        UserDefaults.standard.stringArray(forKey: interestsKey(for: currentUserID)) ?? []
    }

    static func saveInterests(_ interests: [String], for userID: String? = nil) {
        let normalized = Array(Set(interests)).sorted()
        UserDefaults.standard.set(normalized, forKey: interestsKey(for: userID ?? currentUserID))
    }

    static func loadSeenArticleIDs() async -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: seenArticlesKey(for: currentUserID)) ?? [])
    }

    static func markSeen(articleID: String) {
        updateLocalStringArray(forKey: seenArticlesKey(for: currentUserID), appending: articleID)
    }

    static func markLiked(articleID: String) {
        updateLocalStringArray(forKey: likedArticlesKey(for: currentUserID), appending: articleID)
    }

    static func saveArticle(_ article: Article, completion: @escaping (Bool) -> Void = { _ in }) {
        let savedArticle = SavedArticle(
            title: article.title,
            url: article.url,
            description: article.description,
            urlToImage: article.urlToImage
        )
        saveGuestArticle(savedArticle)
        completion(true)
    }

    static func loadSavedArticles() async -> [SavedArticle] {
        loadGuestSavedArticles()
    }

    static func saveLocation(_ location: String) {
        guard let userID = currentUserID else { return }
        UserDefaults.standard.set(location, forKey: locationKeyPrefix + userID)
    }

    static func saveProfilePhoto(_ image: UIImage) {
        guard let userID = currentUserID,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        UserDefaults.standard.set(data, forKey: profilePhotoKeyPrefix + userID)
    }

    static func loadProfilePhoto() -> UIImage? {
        guard let userID = currentUserID,
              let data = UserDefaults.standard.data(forKey: profilePhotoKeyPrefix + userID) else {
            return nil
        }

        return UIImage(data: data)
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

    private static func interestsKey(for userID: String?) -> String {
        userID == nil ? guestInterestsKey : "apollo.interests.\(userID!)"
    }

    private static func seenArticlesKey(for userID: String?) -> String {
        userID == nil ? guestSeenArticlesKey : "apollo.seen.\(userID!)"
    }

    private static func likedArticlesKey(for userID: String?) -> String {
        userID == nil ? guestLikedArticlesKey : "apollo.liked.\(userID!)"
    }
}
