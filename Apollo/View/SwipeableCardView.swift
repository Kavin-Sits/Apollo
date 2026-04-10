//
//  SwipeableCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI

struct SwipeableCardView: View {
    let refreshToken: UUID
    @EnvironmentObject var activeArticleVM: ActiveArticleViewModel
    @EnvironmentObject var nightModeManager: NightModeManager

    @State private var displayedArticles: [RecommendedArticle] = []
    @State private var interests: [String] = []
    @State private var recommendationState = RecommendationState(profile: nil, topicPreferences: [])
    @State private var profile: SupabaseProfile?
    @State private var selectedArticle: Article?
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0

    let haptics = UINotificationFeedbackGenerator()
    @ObservedObject private var soundEffectManager = SoundEffectManager()

    private let swipeThreshold: CGFloat = 96
    private let maxVisibleCards = 3

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if displayedArticles.isEmpty {
                    emptyState(height: geometry.size.height)
                } else {
                    ZStack {
                        ForEach(Array(displayedArticles.prefix(maxVisibleCards).enumerated()), id: \.element.id) { offset, recommendation in
                            let isTopCard = offset == 0
                            let article = recommendation.article

                            CardView(article: article, recommendationExplanation: recommendation.explanation)
                                .environmentObject(nightModeManager)
                                .frame(height: geometry.size.height)
                                .scaleEffect(cardScale(for: offset))
                                .offset(
                                    x: isTopCard ? dragOffset.width : 0,
                                    y: isTopCard ? dragOffset.height : CGFloat(offset * 18)
                                )
                                .rotationEffect(.degrees(isTopCard ? dragRotation : 0))
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
                                    recommendationState = AppSession.markOpened(
                                        article: article,
                                        currentState: recommendationState,
                                        profile: profile
                                    ) ?? recommendationState
                                    rerankDisplayedArticles()
                                }
                                .gesture(dragGesture, including: isTopCard ? .all : .subviews)
                                .animation(.interactiveSpring(response: 0.26, dampingFraction: 0.84, blendDuration: 0.18), value: dragOffset)
                                .animation(.interactiveSpring(response: 0.34, dampingFraction: 0.84, blendDuration: 0.2), value: displayedArticles)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .sheet(item: $selectedArticle) {
            SafariView(url: $0.articleURL)
        }
        .task {
            await loadDisplayedArticles()
        }
        .onChange(of: refreshToken) {
            Task {
                await loadDisplayedArticles()
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                dragRotation = Double(value.translation.width / 18)
            }
            .onEnded { value in
                let horizontalMovement = value.translation.width
                let predictedMovement = value.predictedEndTranslation.width

                if horizontalMovement < -swipeThreshold || predictedMovement < -swipeThreshold {
                    completeSwipe(liked: false)
                } else if horizontalMovement > swipeThreshold || predictedMovement > swipeThreshold {
                    completeSwipe(liked: true)
                } else {
                    resetDragState()
                }
            }
    }

    private var feedbackOpacity: Double {
        min(abs(dragOffset.width) / swipeThreshold, 1)
    }

    @ViewBuilder
    private func swipeFeedback(for article: Article) -> some View {
        if dragOffset.width > 0 {
            swipeBadge(systemName: "heart.fill", fill: Color.green.opacity(0.92))
        } else if dragOffset.width < 0 {
            swipeBadge(systemName: "xmark", fill: Color.red.opacity(0.9))
        } else {
            Text(article.source.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func swipeBadge(systemName: String, fill: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 54, height: 54)
            .background(Circle().fill(fill))
            .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
            .shadow(color: fill.opacity(0.28), radius: 12, x: 0, y: 6)
    }

    private func cardScale(for offset: Int) -> CGFloat {
        1 - CGFloat(offset) * 0.04
    }

    private func completeSwipe(liked: Bool) {
        if soundEffectManager.soundEnabled {
            playSound(sound: "swipe", type: "wav")
        }

        haptics.notificationOccurred(.success)

        guard let topRecommendation = displayedArticles.first else { return }
        let article = topRecommendation.article

        if liked {
            addLikedArticleToUser(article)
        } else {
            addDismissedArticleToUser(article)
        }

        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.8, blendDuration: 0.16)) {
            dragOffset = CGSize(width: liked ? 560 : -560, height: 22)
            dragRotation = liked ? 22 : -22
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            guard !displayedArticles.isEmpty else { return }
            displayedArticles.removeFirst()
            rerankDisplayedArticles()
            resetDragState()
            activeArticleVM.activeArticle = displayedArticles.first?.article
        }
    }

    private func resetDragState() {
        dragOffset = .zero
        dragRotation = 0
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
        recommendationState = AppSession.markDismissed(
            article: article,
            currentState: recommendationState,
            profile: profile
        ) ?? recommendationState
    }

    private func addLikedArticleToUser(_ article: Article) {
        recommendationState = AppSession.markLiked(
            article: article,
            currentState: recommendationState,
            profile: profile
        ) ?? recommendationState
    }

    @MainActor
    private func loadDisplayedArticles() async {
        displayedArticles = []

        interests = await AppSession.loadInterests()
        profile = await AppSession.loadProfile()
        recommendationState = await AppSession.loadRecommendationState(interests: interests, profile: profile)
        let seenArticles = await AppSession.loadSeenArticleIDs()
        let context = RecommendationRefreshContext(
            interests: interests,
            profile: profile,
            recommendationState: recommendationState,
            seenArticleIDs: seenArticles
        )
        displayedArticles = await RecommendationService.shared.loadArticles(for: context)
        activeArticleVM.activeArticle = displayedArticles.first?.article
    }

    private func rerankDisplayedArticles() {
        let context = RecommendationRefreshContext(
            interests: interests,
            profile: profile,
            recommendationState: recommendationState,
            seenArticleIDs: []
        )
        displayedArticles = RecommendationService.shared.rerankExistingArticles(
            displayedArticles.map(\.article),
            context: context
        )
    }
}

#Preview {
    SwipeableCardView(refreshToken: UUID())
}
