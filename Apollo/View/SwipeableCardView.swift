//
//  SwipeableCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI

struct SwipeableCardView: View {

    @StateObject var articleNewsVM = ArticleNewsViewModel()
    @EnvironmentObject var activeArticleVM: ActiveArticleViewModel
    @EnvironmentObject var nightModeManager: NightModeManager

    @State private var displayedArticles: [Article] = []
    @State private var selectedArticle: Article?
    @State private var dragOffset: CGSize = .zero

    let haptics = UINotificationFeedbackGenerator()
    @ObservedObject private var soundEffectManager = SoundEffectManager()

    private let swipeThreshold: CGFloat = 110
    private let maxVisibleCards = 3

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if displayedArticles.isEmpty {
                    emptyState(height: geometry.size.height)
                } else {
                    ZStack {
                        ForEach(Array(displayedArticles.prefix(maxVisibleCards).enumerated()), id: \.element.id) { offset, article in
                            let isTopCard = offset == 0

                            CardView(article: article)
                                .environmentObject(nightModeManager)
                                .frame(height: geometry.size.height)
                                .scaleEffect(cardScale(for: offset))
                                .offset(
                                    x: isTopCard ? dragOffset.width : 0,
                                    y: isTopCard ? dragOffset.height : CGFloat(offset * 14)
                                )
                                .rotationEffect(.degrees(isTopCard ? Double(dragOffset.width / 18) : 0))
                                .overlay(alignment: .top) {
                                    swipeFeedback(for: article)
                                        .opacity(isTopCard ? feedbackOpacity : 0)
                                        .padding(.top, 24)
                                }
                                .zIndex(Double(maxVisibleCards - offset))
                                .allowsHitTesting(isTopCard)
                                .onTapGesture {
                                    selectedArticle = article
                                    activeArticleVM.activeArticle = article
                                    AppSession.markOpened(article: article)
                                }
                                .gesture(dragGesture, including: isTopCard ? .all : .subviews)
                                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: dragOffset)
                                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: displayedArticles)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(item: $selectedArticle) {
            SafariView(url: $0.articleURL)
        }
        .task {
            await loadDisplayedArticles()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let horizontalMovement = value.translation.width
                let predictedMovement = value.predictedEndTranslation.width

                if horizontalMovement < -swipeThreshold || predictedMovement < -swipeThreshold {
                    completeSwipe(liked: false)
                } else if horizontalMovement > swipeThreshold || predictedMovement > swipeThreshold {
                    completeSwipe(liked: true)
                } else {
                    dragOffset = .zero
                }
            }
    }

    private var feedbackOpacity: Double {
        min(abs(dragOffset.width) / swipeThreshold, 1)
    }

    @ViewBuilder
    private func swipeFeedback(for article: Article) -> some View {
        if dragOffset.width > 0 {
            swipeBadge(text: "Save", systemName: "heart.fill", fill: Color.green.opacity(0.92))
        } else if dragOffset.width < 0 {
            swipeBadge(text: "Skip", systemName: "xmark", fill: Color.red.opacity(0.9))
        } else {
            Text(article.source.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func swipeBadge(text: String, systemName: String, fill: Color) -> some View {
        Label(text, systemImage: systemName)
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(fill))
    }

    private func cardScale(for offset: Int) -> CGFloat {
        1 - CGFloat(offset) * 0.05
    }

    private func completeSwipe(liked: Bool) {
        if soundEffectManager.soundEnabled {
            playSound(sound: "swipe", type: "wav")
        }

        haptics.notificationOccurred(.success)

        guard let article = displayedArticles.first else { return }

        if liked {
            addLikedArticleToUser(article)
        } else {
            addDismissedArticleToUser(article)
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            dragOffset = CGSize(width: liked ? 500 : -500, height: 30)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            guard !displayedArticles.isEmpty else { return }
            displayedArticles.removeFirst()
            dragOffset = .zero
            activeArticleVM.activeArticle = displayedArticles.first
        }
    }

    private func emptyState(height: CGFloat) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.95))

            Text("You’re caught up for now.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppStyle.heroTextPrimary)

            Text("Check back later for a fresh batch of stories. The more you save and skip, the sharper your feed will get.")
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppStyle.heroTextSecondary)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .frame(height: max(height * 0.7, 420))
        .background(AppStyle.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 16)
    }

    private func addDismissedArticleToUser(_ article: Article) {
        AppSession.markDismissed(article: article)
    }

    private func addLikedArticleToUser(_ article: Article) {
        AppSession.markLiked(article: article)
    }

    @MainActor
    private func loadDisplayedArticles() async {
        displayedArticles = []

        let interests = await AppSession.loadInterests()
        let seenArticles = await AppSession.loadSeenArticleIDs()
        let categories = mappedCategories(from: interests)
        let quantityToAdd = max(2, 12 / max(categories.count, 1))

        for category in categories {
            articleNewsVM.fetchTaskToken = FetchTaskToken(category: category, token: Date())
            await articleNewsVM.loadArticles()

            guard case let .success(articles) = articleNewsVM.phase else {
                continue
            }

            let filteredArticles = articles.filter { article in
                article.url != "https://removed.com" &&
                !seenArticles.contains(article.id) &&
                !displayedArticles.contains(where: { $0.url == article.url })
            }

            displayedArticles.append(contentsOf: Array(filteredArticles.prefix(quantityToAdd)))
        }

        displayedArticles.shuffle()
        activeArticleVM.activeArticle = displayedArticles.first
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
}

#Preview {
    SwipeableCardView()
}
