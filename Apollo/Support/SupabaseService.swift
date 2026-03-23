//
//  SupabaseService.swift
//  Apollo
//

import Foundation

struct SupabaseUser: Codable {
    let id: String
    let email: String?
}

struct SupabaseSession: Codable {
    let accessToken: String?
    let refreshToken: String?
    let expiresAt: TimeInterval?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}

private struct SupabaseAuthResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let expiresAt: TimeInterval?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }

    var session: SupabaseSession? {
        guard accessToken != nil || refreshToken != nil || user != nil else {
            return nil
        }

        return SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: user
        )
    }
}

struct SupabaseProfile: Codable {
    let id: String
    let email: String
    let fullName: String?
    let dateOfBirth: String?
    let location: String?
    let occupation: String?
    let profilePhotoURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case location
        case occupation
        case profilePhotoURL = "profile_photo_url"
    }
}

private struct UserInterestsRow: Codable {
    let userID: String
    let interests: [String]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case interests = "interest"
    }
}

enum ArticleFeedbackAction: String, CaseIterable {
    case seen
    case liked
    case disliked
    case saved
    case opened
}

enum SupabaseServiceError: LocalizedError {
    case missingConfiguration
    case invalidConfiguration(String)
    case unauthenticated
    case unsupported(String)
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase configuration is missing."
        case .invalidConfiguration(let message):
            return message
        case .unauthenticated:
            return "You need to be signed in to do that."
        case .unsupported(let message):
            return message
        case .invalidResponse:
            return "Supabase returned an invalid response."
        case .api(let message):
            return message
        }
    }
}

final class SupabaseService {
    static let shared = SupabaseService()

    private let sessionStorageKey = "apollo.supabase.session"
    private let urlSession = URLSession.shared
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    private init() {}

    private(set) var session: SupabaseSession? {
        get {
            guard let data = UserDefaults.standard.data(forKey: sessionStorageKey),
                  let session = try? jsonDecoder.decode(SupabaseSession.self, from: data) else {
                return nil
            }
            return session
        }
        set {
            if let newValue, let data = try? jsonEncoder.encode(newValue) {
                UserDefaults.standard.set(data, forKey: sessionStorageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: sessionStorageKey)
            }
        }
    }

    var isAuthenticated: Bool {
        currentUser != nil && currentAccessToken != nil
    }

    var currentUser: SupabaseUser? {
        session?.user
    }

    var currentUserID: String? {
        currentUser?.id
    }

    var currentUserEmail: String? {
        currentUser?.email
    }

    func signUp(email: String, password: String) async throws -> SupabaseSession? {
        let body = [
            "email": email,
            "password": password
        ]

        let response: SupabaseAuthResponse = try await sendAuthRequest(
            path: "/auth/v1/signup",
            method: "POST",
            body: body,
            requiresAuth: false
        )

        if let session = response.session {
            self.session = session
        }

        return response.session
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        let body = [
            "email": email,
            "password": password
        ]

        let response: SupabaseAuthResponse = try await sendAuthRequest(
            path: "/auth/v1/token?grant_type=password",
            method: "POST",
            body: body,
            requiresAuth: false
        )

        guard let session = response.session else {
            throw SupabaseServiceError.invalidResponse
        }

        self.session = session
        return session
    }

    func signOut() async {
        defer { session = nil }

        guard currentAccessToken != nil else {
            return
        }

        _ = try? await sendNoContentAuthRequest(path: "/auth/v1/logout", method: "POST")
    }

    func resetPassword(email: String) async throws {
        let body = [
            "email": email
        ]

        _ = try await sendAuthRequest(
            path: "/auth/v1/recover",
            method: "POST",
            body: body,
            requiresAuth: false
        ) as EmptyResponse
    }

    func updatePassword(_ password: String) async throws {
        let body = [
            "password": password
        ]

        let response: SupabaseAuthResponse = try await sendAuthRequest(
            path: "/auth/v1/user",
            method: "PUT",
            body: body,
            requiresAuth: true
        )

        if let updatedSession = response.session {
            session = updatedSession
        }
    }

    func fetchProfile() async throws -> SupabaseProfile? {
        guard let userID = currentUserID else {
            throw SupabaseServiceError.unauthenticated
        }

        let profiles: [SupabaseProfile] = try await sendRestRequest(
            path: "/rest/v1/profiles?id=eq.\(userID)&select=*",
            method: "GET",
            body: nil as String?
        )
        return profiles.first
    }

    func upsertProfile(
        fullName: String? = nil,
        dateOfBirth: String? = nil,
        location: String? = nil,
        occupation: String? = nil,
        profilePhotoURL: String? = nil
    ) async throws {
        struct ProfileUpsertPayload: Encodable {
            let id: String
            let email: String
            let fullName: String?
            let dateOfBirth: String?
            let location: String?
            let occupation: String?
            let profilePhotoURL: String?

            enum CodingKeys: String, CodingKey {
                case id
                case email
                case fullName = "full_name"
                case dateOfBirth = "date_of_birth"
                case location
                case occupation
                case profilePhotoURL = "profile_photo_url"
            }
        }

        guard let userID = currentUserID, let email = currentUserEmail else {
            throw SupabaseServiceError.unauthenticated
        }

        let payload = ProfileUpsertPayload(
            id: userID,
            email: email,
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            location: location,
            occupation: occupation,
            profilePhotoURL: profilePhotoURL
        )

        _ = try await sendRestRequest(
            path: "/rest/v1/profiles?on_conflict=id",
            method: "POST",
            body: [payload],
            extraHeaders: [
                "Prefer": "resolution=merge-duplicates,return=representation"
            ]
        ) as [SupabaseProfile]
    }

    func fetchInterests() async throws -> [String] {
        guard let userID = currentUserID else {
            throw SupabaseServiceError.unauthenticated
        }

        let rows: [UserInterestsRow] = try await sendRestRequest(
            path: "/rest/v1/user_interests?user_id=eq.\(userID)&select=interest",
            method: "GET",
            body: nil as String?
        )
        return rows.first?.interests ?? []
    }

    func replaceInterests(_ interests: [String]) async throws {
        guard let userID = currentUserID else {
            throw SupabaseServiceError.unauthenticated
        }

        let unique = Array(Set(interests)).sorted()

        let payload = [
            UserInterestsRow(
                userID: userID,
                interests: unique
            )
        ]

        _ = try await sendRestRequest(
            path: "/rest/v1/user_interests?on_conflict=user_id",
            method: "POST",
            body: payload,
            extraHeaders: ["Prefer": "resolution=merge-duplicates,return=representation"]
        ) as [UserInterestsRow]
    }

    func fetchSavedArticles() async throws -> [SavedArticle] {
        guard let userID = currentUserID else {
            throw SupabaseServiceError.unauthenticated
        }

        struct SavedArticleRow: Codable {
            let title: String
            let url: String
            let description: String?
            let urlToImage: String?

            enum CodingKeys: String, CodingKey {
                case title
                case url
                case description
                case urlToImage = "url_to_image"
            }
        }

        let rows: [SavedArticleRow] = try await sendRestRequest(
            path: "/rest/v1/saved_articles?user_id=eq.\(userID)&select=title,url,description,url_to_image&order=saved_at.desc",
            method: "GET",
            body: nil as String?
        )

        return rows.map {
            SavedArticle(title: $0.title, url: $0.url, description: $0.description, urlToImage: $0.urlToImage)
        }
    }

    func fetchArticleFeedbackURLs(for actions: [ArticleFeedbackAction]) async throws -> Set<String> {
        guard let userID = currentUserID else {
            throw SupabaseServiceError.unauthenticated
        }

        let actionQuery = actions
            .map(\.rawValue)
            .joined(separator: ",")

        let rows: [[String: String]] = try await sendRestRequest(
            path: "/rest/v1/article_feedback?user_id=eq.\(userID)&action=in.(\(actionQuery))&select=article_url",
            method: "GET",
            body: nil as String?
        )

        return Set(rows.compactMap { $0["article_url"] })
    }

    func saveArticle(_ article: Article) async throws {
        struct SavedArticleInsertPayload: Encodable {
            let userID: String
            let title: String
            let url: String
            let description: String?
            let urlToImage: String?

            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
                case title
                case url
                case description
                case urlToImage = "url_to_image"
            }
        }

        guard let userID = currentUserID else {
            throw SupabaseServiceError.unauthenticated
        }

        let payload = [
            SavedArticleInsertPayload(
                userID: userID,
                title: article.title,
                url: article.url,
                description: article.description,
                urlToImage: article.urlToImage
            )
        ]

        _ = try await sendRestRequest(
            path: "/rest/v1/saved_articles",
            method: "POST",
            body: payload,
            extraHeaders: ["Prefer": "return=representation"]
        ) as [[String: String]]
    }

    func recordArticleFeedback(articleURL: String, actions: [ArticleFeedbackAction]) async throws {
        struct ArticleFeedbackPayload: Encodable {
            let userID: String
            let articleURL: String
            let action: String

            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
                case articleURL = "article_url"
                case action
            }
        }

        guard let userID = currentUserID else {
            throw SupabaseServiceError.unauthenticated
        }

        let uniqueActions = Array(Set(actions))
        let payload = uniqueActions.map { action in
            ArticleFeedbackPayload(
                userID: userID,
                articleURL: articleURL,
                action: action.rawValue
            )
        }

        _ = try await sendRestRequest(
            path: "/rest/v1/article_feedback?on_conflict=user_id,article_url,action",
            method: "POST",
            body: payload,
            extraHeaders: ["Prefer": "resolution=merge-duplicates,return=representation"]
        ) as [[String: String]]
    }

    private var publishableKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private var currentAccessToken: String? {
        session?.accessToken
    }

    private func makeRequest(
        path: String,
        method: String,
        bodyData: Data?,
        requiresAuth: Bool,
        extraHeaders: [String: String] = [:]
    ) throws -> URLRequest {
        guard let publishableKey else {
            throw SupabaseServiceError.missingConfiguration
        }
        let baseURL = try validatedProjectURL()

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let sanitizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let pathParts = sanitizedPath.split(separator: "?", maxSplits: 1).map(String.init)
        components?.path = "/" + pathParts[0]
        if pathParts.count == 2 {
            components?.percentEncodedQuery = pathParts[1]
        }
        guard let url = components?.url else {
            throw SupabaseServiceError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")

        if requiresAuth {
            guard let token = currentAccessToken else {
                throw SupabaseServiceError.unauthenticated
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func validatedProjectURL() throws -> URL {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            throw SupabaseServiceError.missingConfiguration
        }

        let trimmedValue = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        guard !trimmedValue.isEmpty else {
            throw SupabaseServiceError.missingConfiguration
        }

        let normalizedValue: String
        if trimmedValue.contains("://") {
            normalizedValue = trimmedValue
        } else if trimmedValue.contains(".") {
            normalizedValue = "https://\(trimmedValue)"
        } else {
            throw SupabaseServiceError.invalidConfiguration(
                "Supabase URL is invalid (\(trimmedValue)). Check SUPABASE_URL in Secrets.xcconfig."
            )
        }

        guard let url = URL(string: normalizedValue), let host = url.host, !host.isEmpty else {
            throw SupabaseServiceError.invalidConfiguration(
                "Supabase URL is invalid (\(trimmedValue)). Check SUPABASE_URL in Secrets.xcconfig."
            )
        }

        return url
    }

    private func sendAuthRequest<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body,
        requiresAuth: Bool,
        extraHeaders: [String: String] = [:]
    ) async throws -> T {
        let data = try jsonEncoder.encode(body)
        let request = try makeRequest(path: path, method: method, bodyData: data, requiresAuth: requiresAuth, extraHeaders: extraHeaders)
        return try await execute(request)
    }

    private func sendNoContentAuthRequest(path: String, method: String) async throws {
        let request = try makeRequest(path: path, method: method, bodyData: nil, requiresAuth: true)
        _ = try await execute(request) as EmptyResponse
    }

    private func sendRestRequest<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body,
        extraHeaders: [String: String] = [:]
    ) async throws -> T {
        let data = try jsonEncoder.encode(body)
        let request = try makeRequest(path: path, method: method, bodyData: data, requiresAuth: true, extraHeaders: extraHeaders)
        return try await execute(request)
    }

    private func sendRestRequest<T: Decodable>(
        path: String,
        method: String,
        body: String?,
        extraHeaders: [String: String] = [:]
    ) async throws -> T {
        let request = try makeRequest(path: path, method: method, bodyData: body?.data(using: .utf8), requiresAuth: true, extraHeaders: extraHeaders)
        return try await execute(request)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let message = try? jsonDecoder.decode(SupabaseAPIError.self, from: data).message {
                throw SupabaseServiceError.api(message)
            }
            throw SupabaseServiceError.api(String(data: data, encoding: .utf8) ?? "Supabase request failed.")
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        if T.self == EmptyArrayResponse.self {
            return EmptyArrayResponse() as! T
        }

        return try jsonDecoder.decode(T.self, from: data)
    }
}

private struct SupabaseAPIError: Decodable {
    let message: String
}

private struct EmptyResponse: Decodable {}
private struct EmptyArrayResponse: Decodable {}
