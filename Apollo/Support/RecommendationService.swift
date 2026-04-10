import Foundation

struct RecommendedArticle: Identifiable, Equatable {
    let article: Article
    let explanation: String
    let debugReasons: [String]
    let score: Double

    var id: String { article.id }
}

struct RecommendationProfile: Codable, Equatable {
    let userID: String
    var ageBucket: String?
    var locationCountry: String?
    var occupationKeywords: [String]
    var positiveQueryTerms: [String]
    var negativeQueryTerms: [String]
    var lastBackfilledAt: Date?
    var updatedAt: Date?

    init(
        userID: String,
        ageBucket: String? = nil,
        locationCountry: String? = nil,
        occupationKeywords: [String] = [],
        positiveQueryTerms: [String] = [],
        negativeQueryTerms: [String] = [],
        lastBackfilledAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userID = userID
        self.ageBucket = ageBucket
        self.locationCountry = locationCountry
        self.occupationKeywords = occupationKeywords
        self.positiveQueryTerms = occupationKeywords.isEmpty ? [] : RecommendationService.normalizedUniqueTerms(from: occupationKeywords)
        self.negativeQueryTerms = RecommendationService.normalizedUniqueTerms(from: negativeQueryTerms)
        if !positiveQueryTerms.isEmpty {
            self.positiveQueryTerms = RecommendationService.normalizedUniqueTerms(from: positiveQueryTerms)
        }
        self.lastBackfilledAt = lastBackfilledAt
        self.updatedAt = updatedAt
    }
}

struct TopicPreference: Codable, Equatable, Identifiable {
    let userID: String
    let topic: String
    var score: Double
    var positiveInteractions: Int
    var negativeInteractions: Int
    var lastPositiveAt: Date?
    var lastNegativeAt: Date?
    var updatedAt: Date?

    var id: String { topic }
}

struct RecommendationState: Equatable {
    var profile: RecommendationProfile?
    var topicPreferences: [TopicPreference]
}

struct RecommendationRefreshContext {
    let interests: [String]
    let profile: SupabaseProfile?
    let recommendationState: RecommendationState
    let seenArticleIDs: Set<String>
}

enum RecommendationFeedbackKind {
    case liked
    case disliked
    case opened
    case saved
}

struct RecommendationFeedbackUpdate {
    let profile: RecommendationProfile?
    let topicPreferences: [TopicPreference]
}

struct NewsQueryPlan {
    enum Endpoint {
        case topHeadlines
        case everything
    }

    let endpoint: Endpoint
    let query: String?
    let category: Category?
    let country: String?
    let pageSize: Int
}

final class RecommendationService {
    static let shared = RecommendationService()

    private init() {}

    func loadArticles(for context: RecommendationRefreshContext) async -> [RecommendedArticle] {
        let plans = queryPlans(for: context)
        var merged: [Article] = []
        var seenURLs = Set<String>()

        for plan in plans {
            let fetched = try? await NewsAPI.shared.fetch(using: plan)
            for article in fetched ?? [] {
                guard article.url != "https://removed.com",
                      !context.seenArticleIDs.contains(article.id),
                      !seenURLs.contains(article.url) else {
                    continue
                }

                seenURLs.insert(article.url)
                merged.append(article)
            }
        }

        let ranked = rank(articles: merged, context: context)
        return Array(ranked.prefix(24))
    }

    func rerankExistingArticles(_ articles: [Article], context: RecommendationRefreshContext) -> [RecommendedArticle] {
        rank(articles: articles, context: context)
    }

    func applyFeedback(
        for article: Article,
        kind: RecommendationFeedbackKind,
        currentState: RecommendationState,
        profile: SupabaseProfile?
    ) -> RecommendationFeedbackUpdate {
        let userID = currentState.profile?.userID ?? AppSession.currentUserID ?? AppSession.guestUserID
        var nextProfile = currentState.profile ?? buildInitialProfile(userID: userID, profile: profile)
        var topicMap = Dictionary(uniqueKeysWithValues: currentState.topicPreferences.map { ($0.topic, $0) })
        let now = Date()
        let extractedTopics = extractedTerms(from: article).prefix(10)
        let delta = scoreDelta(for: kind)

        for topic in extractedTopics {
            var preference = topicMap[topic] ?? TopicPreference(
                userID: userID,
                topic: topic,
                score: 0,
                positiveInteractions: 0,
                negativeInteractions: 0,
                lastPositiveAt: nil,
                lastNegativeAt: nil,
                updatedAt: nil
            )

            preference.score += delta
            preference.updatedAt = now

            if delta > 0 {
                preference.positiveInteractions += 1
                preference.lastPositiveAt = now
            } else {
                preference.negativeInteractions += 1
                preference.lastNegativeAt = now
            }

            topicMap[topic] = preference
        }

        let sortedTopics = topicMap.values.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.topic < rhs.topic
            }
            return lhs.score > rhs.score
        }

        nextProfile.positiveQueryTerms = Array(sortedTopics.filter { $0.score > 0 }.prefix(12).map(\.topic))
        nextProfile.negativeQueryTerms = Array(sortedTopics.filter { $0.score < 0 }.prefix(10).map(\.topic))
        nextProfile.updatedAt = now

        return RecommendationFeedbackUpdate(profile: nextProfile, topicPreferences: sortedTopics)
    }

    func buildInitialProfile(userID: String, profile: SupabaseProfile?) -> RecommendationProfile {
        let ageBucket = profile?.dateOfBirth.flatMap(ageBucket(from:))
        let locationCountry = profile?.location.flatMap(countryName(from:))
        let occupationKeywords = occupationTerms(from: profile?.occupation)

        return RecommendationProfile(
            userID: userID,
            ageBucket: ageBucket,
            locationCountry: locationCountry,
            occupationKeywords: occupationKeywords,
            positiveQueryTerms: occupationKeywords,
            negativeQueryTerms: []
        )
    }

    func buildBackfilledState(
        userID: String,
        profile: SupabaseProfile?,
        interests: [String],
        savedArticles: [SavedArticle]
    ) -> RecommendationState {
        var recommendationProfile = buildInitialProfile(userID: userID, profile: profile)
        let seedTerms = Self.normalizedUniqueTerms(from: interestTerms(from: interests) + recommendationProfile.occupationKeywords)
        recommendationProfile.positiveQueryTerms = seedTerms
        recommendationProfile.lastBackfilledAt = Date()
        recommendationProfile.updatedAt = Date()

        let savedTopicScores = savedArticles.flatMap { extractedTerms(title: $0.title, description: $0.description ?? "") }
        let groupedScores = Dictionary(savedTopicScores.map { ($0, 1.4) }, uniquingKeysWith: +)
        let topicPreferences = groupedScores.map { topic, score in
            TopicPreference(
                userID: userID,
                topic: topic,
                score: score,
                positiveInteractions: 1,
                negativeInteractions: 0,
                lastPositiveAt: Date(),
                lastNegativeAt: nil,
                updatedAt: Date()
            )
        }
        .sorted { $0.score > $1.score }

        return RecommendationState(profile: recommendationProfile, topicPreferences: topicPreferences)
    }

    private func queryPlans(for context: RecommendationRefreshContext) -> [NewsQueryPlan] {
        let interests = interestTerms(from: context.interests)
        let locationTerms = context.recommendationState.profile?.locationCountry.map { [$0] } ?? []
        let ageTerms = ageBucketTerms(for: context.recommendationState.profile?.ageBucket)
        let occupationTerms = context.recommendationState.profile?.occupationKeywords ?? []
        let negativeTerms = Set(context.recommendationState.profile?.negativeQueryTerms ?? [])
        let topicPreferences = context.recommendationState.topicPreferences

        let topPositiveTopics = topicPreferences
            .filter { $0.score > 0.1 }
            .prefix(8)
            .map(\.topic)
        let suppressedTopics = suppressedTopics(from: topicPreferences, negativeTerms: negativeTerms)
        let explorationTerms = Self.normalizedUniqueTerms(from: interests + ageTerms + occupationTerms)
            .filter { !topPositiveTopics.contains($0) }
            .prefix(6)

        let categoryPlans = mappedCategories(from: context.interests).prefix(2).map { category in
            NewsQueryPlan(endpoint: .topHeadlines, query: nil, category: category, country: "us", pageSize: 14)
        }

        var plans: [NewsQueryPlan] = [
            NewsQueryPlan(
                endpoint: .everything,
                query: buildQuery(from: Array(interests.prefix(3) + topPositiveTopics.prefix(3) + locationTerms.prefix(1)), excluding: suppressedTopics),
                category: nil,
                country: nil,
                pageSize: 20
            ),
            NewsQueryPlan(
                endpoint: .everything,
                query: buildQuery(from: Array(occupationTerms.prefix(3) + topPositiveTopics.prefix(2) + ageTerms.prefix(2)), excluding: suppressedTopics),
                category: nil,
                country: nil,
                pageSize: 20
            ),
            NewsQueryPlan(
                endpoint: .everything,
                query: buildQuery(from: Array(explorationTerms), excluding: suppressedTopics),
                category: nil,
                country: nil,
                pageSize: 20
            )
        ]

        plans.append(contentsOf: categoryPlans)

        return plans.filter { plan in
            if case .everything = plan.endpoint {
                return !(plan.query?.isEmpty ?? true)
            }
            return true
        }
    }

    private func rank(articles: [Article], context: RecommendationRefreshContext) -> [RecommendedArticle] {
        let profile = context.recommendationState.profile
        let positiveTopics = context.recommendationState.topicPreferences.filter { $0.score > 0 }.sorted { $0.score > $1.score }
        let positiveTopicMap = Dictionary(uniqueKeysWithValues: positiveTopics.map { ($0.topic, $0.score) })
        let negativeTopicMap = Dictionary(uniqueKeysWithValues: context.recommendationState.topicPreferences.filter { $0.score < 0 }.map { ($0.topic, abs($0.score)) })
        let interestTerms = Set(Self.normalizedUniqueTerms(from: self.interestTerms(from: context.interests)))
        let occupationTerms = Set(profile?.occupationKeywords ?? [])
        let ageTerms = Set(ageBucketTerms(for: profile?.ageBucket))
        let locationTerms = Set(profile?.locationCountry.map { [Self.normalizeTerm($0)] } ?? [])
        let topPositiveTopics = Set(positiveTopics.prefix(12).map(\.topic))
        let suppressedTopics = suppressedTopics(from: context.recommendationState.topicPreferences, negativeTerms: Set(profile?.negativeQueryTerms ?? []))

        return articles.map { article in
            let articleTerms = Set(extractedTerms(from: article))
            let positiveMatches = articleTerms.intersection(topPositiveTopics)
            let interestMatches = articleTerms.intersection(interestTerms)
            let occupationMatches = articleTerms.intersection(occupationTerms)
            let ageMatches = articleTerms.intersection(ageTerms)
            let locationMatches = articleTerms.intersection(locationTerms)
            let suppressedMatches = articleTerms.intersection(suppressedTopics)

            var score = 0.0
            score += Double(positiveMatches.count) * 2.8
            score += interestMatches.isEmpty ? 0 : 2.2
            score += Double(occupationMatches.count) * 1.9
            score += Double(ageMatches.count) * 1.4
            score += Double(locationMatches.count) * 1.1
            score += articleRecencyBonus(for: article)
            score += noveltyBonus(for: articleTerms, topPositiveTopics: topPositiveTopics, interestTerms: interestTerms)

            for term in articleTerms {
                score += positiveTopicMap[term] ?? 0
                score -= negativeTopicMap[term] ?? 0
            }

            if !suppressedMatches.isEmpty {
                score -= 4.5
            }

            let explanation = explanation(
                interestMatches: Array(interestMatches),
                occupationMatches: Array(occupationMatches),
                ageMatches: Array(ageMatches),
                locationMatches: Array(locationMatches),
                positiveMatches: Array(positiveMatches),
                suppressedMatches: Array(suppressedMatches),
                profile: profile
            )

            return RecommendedArticle(
                article: article,
                explanation: explanation.primary,
                debugReasons: explanation.debug,
                score: score
            )
        }
        .sorted { lhs, rhs in
            if abs(lhs.score - rhs.score) < 0.01 {
                return lhs.article.publishedAt > rhs.article.publishedAt
            }
            return lhs.score > rhs.score
        }
    }

    private func explanation(
        interestMatches: [String],
        occupationMatches: [String],
        ageMatches: [String],
        locationMatches: [String],
        positiveMatches: [String],
        suppressedMatches: [String],
        profile: RecommendationProfile?
    ) -> (primary: String, debug: [String]) {
        var debug: [String] = []

        if let first = positiveMatches.first {
            debug.append("You engaged with \(first)-related stories")
        }
        if let first = interestMatches.first {
            debug.append("Matches your \(first) interests")
        }
        if let first = occupationMatches.first, let occupation = profile?.occupationKeywords.first {
            debug.append("Connects with your \(occupation) profile through \(first)")
        }
        if let ageBucket = profile?.ageBucket, let first = ageMatches.first {
            debug.append("Resonates with your age group through \(first) (\(ageBucket))")
        }
        if let location = profile?.locationCountry, let first = locationMatches.first {
            debug.append("Relevant in \(location) through \(first)")
        }
        if !suppressedMatches.isEmpty {
            debug.append("Balanced against topics you've skipped recently")
        }

        let primary = debug.first ?? "Recommended from your profile and recent reading habits"
        return (primary, debug)
    }

    private func articleRecencyBonus(for article: Article) -> Double {
        let hoursAgo = max(Date().timeIntervalSince(article.publishedAt) / 3600, 0)
        switch hoursAgo {
        case 0..<12: return 2.1
        case 12..<24: return 1.4
        case 24..<72: return 0.8
        default: return 0.25
        }
    }

    private func noveltyBonus(for articleTerms: Set<String>, topPositiveTopics: Set<String>, interestTerms: Set<String>) -> Double {
        let familiarMatches = articleTerms.intersection(topPositiveTopics).count
        let interestMatches = articleTerms.intersection(interestTerms).count

        if familiarMatches == 0 && interestMatches > 0 {
            return 1.6
        }
        if familiarMatches == 1 {
            return 1.0
        }
        return 0.3
    }

    private func buildQuery(from terms: [String], excluding suppressedTopics: Set<String>) -> String? {
        let selectedTerms = Self.normalizedUniqueTerms(from: terms)
            .filter { !suppressedTopics.contains($0) }
            .prefix(5)

        guard !selectedTerms.isEmpty else {
            return nil
        }

        return selectedTerms.map { "\"\($0)\"" }.joined(separator: " OR ")
    }

    private func suppressedTopics(from topicPreferences: [TopicPreference], negativeTerms: Set<String>) -> Set<String> {
        let now = Date()
        let stronglyNegative = topicPreferences.filter { preference in
            guard preference.score <= -1 else { return false }
            let recoveredPositives = preference.positiveInteractions >= 3
            let isStale = preference.lastNegativeAt.map { now.timeIntervalSince($0) > 7 * 24 * 60 * 60 } ?? false
            return !(recoveredPositives && isStale)
        }
        return Set(stronglyNegative.map(\.topic)).union(negativeTerms)
    }

    private func scoreDelta(for kind: RecommendationFeedbackKind) -> Double {
        switch kind {
        case .saved:
            return 3.2
        case .liked:
            return 2.2
        case .opened:
            return 0.8
        case .disliked:
            return -2.8
        }
    }

    private func occupationTerms(from occupation: String?) -> [String] {
        guard let occupation else { return [] }

        let normalized = Self.normalizeTerm(occupation)
        let mapped: [String: [String]] = [
            "doctor": ["health", "medicine", "research", "hospital"],
            "physician": ["health", "medicine", "research", "hospital"],
            "nurse": ["health", "medicine", "hospital", "care"],
            "engineer": ["technology", "software", "innovation", "ai"],
            "developer": ["technology", "software", "innovation", "ai"],
            "teacher": ["education", "schools", "learning", "policy"],
            "student": ["education", "campus", "technology", "career"],
            "lawyer": ["law", "courts", "policy", "government"],
            "journalist": ["media", "politics", "press", "analysis"],
            "scientist": ["science", "research", "innovation", "climate"],
            "marketer": ["business", "media", "technology", "consumer"],
            "manager": ["business", "leadership", "economy", "markets"]
        ]

        return Self.normalizedUniqueTerms(from: mapped[normalized] ?? [normalized])
    }

    private func interestTerms(from interests: [String]) -> [String] {
        interests.flatMap { interest in
            switch interest.lowercased() {
            case "sports":
                return ["sports", "league", "team", "playoffs"]
            case "business":
                return ["business", "markets", "economy", "finance"]
            case "technology":
                return ["technology", "ai", "software", "innovation"]
            case "health and medicine":
                return ["health", "medicine", "research", "wellness"]
            case "entertainment":
                return ["entertainment", "movies", "music", "streaming"]
            default:
                return [Self.normalizeTerm(interest)]
            }
        }
    }

    private func ageBucketTerms(for bucket: String?) -> [String] {
        switch bucket {
        case "13-17": return ["education", "campus", "social media", "sports"]
        case "18-24": return ["career", "campus", "technology", "culture"]
        case "25-34": return ["career", "housing", "technology", "business"]
        case "35-49": return ["leadership", "economy", "health", "policy"]
        case "50-64": return ["retirement", "markets", "health", "policy"]
        case "65+": return ["retirement", "health", "policy", "travel"]
        default: return []
        }
    }

    private func ageBucket(from rawDate: String) -> String? {
        let formats = ["yyyy-MM-dd", "MM/dd/yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let parsedDate = formats.lazy.compactMap { format -> Date? in
            formatter.dateFormat = format
            return formatter.date(from: rawDate)
        }.first

        guard let parsedDate else { return nil }

        let age = Calendar.current.dateComponents([.year], from: parsedDate, to: Date()).year ?? 0
        switch age {
        case ..<18: return "13-17"
        case 18...24: return "18-24"
        case 25...34: return "25-34"
        case 35...49: return "35-49"
        case 50...64: return "50-64"
        default: return "65+"
        }
    }

    private func countryName(from rawLocation: String) -> String? {
        let trimmed = rawLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if #available(iOS 16, *) {
            if let region = Locale.Region.isoRegions.first(where: { region in
                Locale.current.localizedString(forRegionCode: region.identifier)?.caseInsensitiveCompare(trimmed) == .orderedSame
            }) {
                return Locale.current.localizedString(forRegionCode: region.identifier) ?? trimmed
            }
        } else if let regionCode = Locale.isoRegionCodes.first(where: { regionCode in
            Locale.current.localizedString(forRegionCode: regionCode)?.caseInsensitiveCompare(trimmed) == .orderedSame
        }) {
            return Locale.current.localizedString(forRegionCode: regionCode) ?? trimmed
        }

        if let lastToken = trimmed.split(separator: ",").last {
            let candidate = String(lastToken).trimmingCharacters(in: .whitespacesAndNewlines)
            if !candidate.isEmpty {
                return candidate
            }
        }

        return trimmed
    }

    private func extractedTerms(from article: Article) -> [String] {
        extractedTerms(title: article.title, description: article.descriptionText)
    }

    private func extractedTerms(title: String, description: String) -> [String] {
        let phrases = extractPhrases(from: title) + extractPhrases(from: description)
        let tokens = (title + " " + description)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .filter { $0.count > 2 }
            .filter { !Self.stopWords.contains($0) }

        return Self.normalizedUniqueTerms(from: phrases + tokens)
    }

    private func extractPhrases(from text: String) -> [String] {
        let words = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .filter { $0.count > 2 }
            .filter { !Self.stopWords.contains($0) }

        guard words.count > 1 else {
            return []
        }

        return zip(words, words.dropFirst()).map { "\($0.0) \($0.1)" }
    }

    private func mappedCategories(from interests: [String]) -> [Category] {
        let categories = interests.map { interest in
            switch interest {
            case "Sports":
                return Category.sports
            case "Business":
                return Category.business
            case "Technology":
                return Category.technology
            case "Health and Medicine":
                return Category.health
            case "Entertainment":
                return Category.entertainment
            default:
                return Category.general
            }
        }

        return categories.isEmpty ? [.general] : Array(Set(categories))
    }

    static func normalizedUniqueTerms(from terms: [String]) -> [String] {
        var seen = Set<String>()
        var normalizedTerms: [String] = []

        for term in terms {
            let normalized = normalizeTerm(term)
            guard normalized.count > 2,
                  !stopWords.contains(normalized),
                  !seen.contains(normalized) else {
                continue
            }
            seen.insert(normalized)
            normalizedTerms.append(normalized)
        }

        return normalizedTerms
    }

    static func normalizeTerm(_ value: String) -> String {
        value
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let stopWords: Set<String> = [
        "about", "after", "again", "against", "amid", "among", "around", "because", "before", "below",
        "could", "during", "first", "from", "into", "just", "like", "more", "most", "news", "over",
        "says", "should", "still", "than", "that", "their", "them", "then", "there", "these", "they",
        "this", "those", "today", "under", "very", "what", "when", "where", "which", "while", "with",
        "would", "your"
    ]
}
