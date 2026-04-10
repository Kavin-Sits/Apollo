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
        try await fetch(
            using: NewsQueryPlan(
                endpoint: .topHeadlines,
                query: nil,
                category: category,
                country: "us",
                pageSize: 20
            )
        )
    }

    func fetch(using plan: NewsQueryPlan) async throws -> [Article] {
        guard !apiKey.isEmpty else {
            return fallbackArticles(for: plan.category ?? .general, matching: plan.query)
        }

        let request = generateNewsRequest(using: plan)
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
            return fallbackArticles(for: plan.category ?? .general, matching: plan.query)
        }
    }
    
    private func generateError(code: Int = 1, description: String) -> Error {
        NSError(domain: "NewsAPI", code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    private func generateNewsRequest(using plan: NewsQueryPlan) -> URLRequest {
        let endpointPath = plan.endpoint == .everything ? "everything" : "top-headlines"
        var components = URLComponents(string: "https://newsapi.org/v2/\(endpointPath)")!
        var queryItems = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "pageSize", value: "\(plan.pageSize)")
        ]

        if let query = plan.query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        if let country = plan.country, plan.endpoint == .topHeadlines {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }

        if let category = plan.category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }

        if plan.endpoint == .everything {
            queryItems.append(URLQueryItem(name: "sortBy", value: "publishedAt"))
        }

        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        return request
    }

    private func fallbackArticles(for category: Category, matching query: String? = nil) -> [Article] {
        let bundledArticles = Article.previewData

        var filteredArticles = bundledArticles

        if category != .general {
            filteredArticles = filteredArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(category.text) ||
                article.descriptionText.localizedCaseInsensitiveContains(category.text) ||
                article.source.name.localizedCaseInsensitiveContains(category.text)
            }
        }

        if let query, !query.isEmpty {
            let terms = query
                .replacingOccurrences(of: "\"", with: "")
                .components(separatedBy: " OR ")
                .filter { !$0.isEmpty }

            let queryFiltered = filteredArticles.filter { article in
                terms.contains { term in
                    article.title.localizedCaseInsensitiveContains(term) ||
                    article.descriptionText.localizedCaseInsensitiveContains(term) ||
                    article.source.name.localizedCaseInsensitiveContains(term)
                }
            }

            if !queryFiltered.isEmpty {
                return queryFiltered
            }
        }

        guard category != .general else {
            return filteredArticles
        }

        return filteredArticles.isEmpty ? bundledArticles : filteredArticles
    }
}
