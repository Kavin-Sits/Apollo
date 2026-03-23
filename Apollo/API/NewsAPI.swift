//
//  NewsAPI.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/10/23.
//

import Foundation

struct NewsAPI {
    
    static let shared = NewsAPI()
    private init() {}
    
    private let session = URLSession.shared
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private var apiKey: String {
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "NEWS_API_KEY") as? String
        let processKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"]
        return (bundleKey ?? processKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func fetch(from category: Category) async throws -> [Article] {
        guard !apiKey.isEmpty else {
            return fallbackArticles(for: category)
        }

        let request = generateNewsRequest(from: category)
        do {
            let (data, response) = try await session.data(for: request)
        
            guard let response = response as? HTTPURLResponse else{
                throw generateError(description: "Bad Response")
            }
        
            switch response.statusCode {
            case(200...299), (400...499):
                let apiResponse = try jsonDecoder.decode(NewsAPIResponse.self, from: data)
                if apiResponse.status == "ok" {
                    return apiResponse.articles ?? []
                }
                else{
                    throw generateError(description: apiResponse.message ?? "An error occurred")
                }
            default:
                throw generateError(description: "A server error occurred")
            }
        } catch {
            return fallbackArticles(for: category)
        }
    }
    
    private func generateError(code: Int = 1, description: String) -> Error {
        NSError(domain: "NewsAPI", code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    private func generateNewsRequest(from category: Category) -> URLRequest {
        var components = URLComponents(string: "https://newsapi.org/v2/top-headlines")!
        components.queryItems = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "country", value: "us"),
            URLQueryItem(name: "category", value: category.rawValue),
            URLQueryItem(name: "pageSize", value: "20")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        return request
    }

    private func fallbackArticles(for category: Category) -> [Article] {
        let bundledArticles = Article.previewData

        guard category != .general else {
            return bundledArticles
        }

        let filteredArticles = bundledArticles.filter { article in
            article.title.localizedCaseInsensitiveContains(category.text) ||
            article.descriptionText.localizedCaseInsensitiveContains(category.text) ||
            article.source.name.localizedCaseInsensitiveContains(category.text)
        }

        return filteredArticles.isEmpty ? bundledArticles : filteredArticles
    }
}
