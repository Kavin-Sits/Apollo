//
//  SwipeableCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI
import CoreData

struct SwipeableCardView: View {
    
    @StateObject var articleNewsVM = ArticleNewsViewModel()
    @EnvironmentObject var activeArticleVM: ActiveArticleViewModel
    @GestureState private var dragState = DragState.inactive
    @State private var cardRemovalTransition = AnyTransition.trailingBottom
    @State private var activeCardIndex: Int? = nil
    @State private var displayedArticles: [Article] = []
    @State private var selectedArticle: Article?
    let haptics = UINotificationFeedbackGenerator()
    @ObservedObject private var soundEffectManager = SoundEffectManager()
    var dragAreaThreshold: CGFloat = 65.0
    
    enum DragState {
        case inactive
        case pressing
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive, .pressing:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .dragging:
                return true
            case .pressing, .inactive:
                return false
            }
        }
        
    }
        
    var body: some View {
        ZStack {
            ZStack {
                ForEach(displayedArticles.indices, id: \.self){ index in
                    CardView(article: displayedArticles[index])
                        .onTapGesture {
                            selectedArticle = displayedArticles[index]
                            activeArticleVM.activeArticle = displayedArticles[index]
                            AppSession.markOpened(article: displayedArticles[index])
                        }
                        .overlay(
                            ZStack{
                                Image(systemName: "x.circle")
                                    .modifier(SymbolModifier())
                                    .opacity(activeCardIndex == index && self.dragState.translation.width < -self.dragAreaThreshold ? 1.0 : 0.0)
                                
                                Image(systemName: "heart.circle")
                                    .modifier(SymbolModifier())
                                    .opacity(activeCardIndex == index && self.dragState.translation.width > self.dragAreaThreshold ? 1.0 : 0.0)
                            })
                        .offset(x: activeCardIndex == index ? self.dragState.translation.width : 0,
                                y: activeCardIndex == index ? self.dragState.translation.height : 0)
                        .scaleEffect(self.dragState.isDragging && activeCardIndex == index ? 0.85 : 1.0)
                        .rotationEffect(Angle(degrees: activeCardIndex == index ? Double(self.dragState.translation.width / 12) : 0))
                        .animation(.interpolatingSpring(stiffness: 120, damping: 120), value: dragState.isDragging)
                        .gesture(LongPressGesture(minimumDuration: 0.01)
                            .sequenced(before: DragGesture())
                            .updating(self.$dragState, body: { (value, state, transaction) in
                                switch value {
                                case .first(true):
                                    state = .pressing
                                case .second(true, let drag):
                                    if activeCardIndex == index {
                                        state = .dragging(translation: drag?.translation ?? .zero)
                                    }
                                default:
                                    break
                                }
                            })
                            .onChanged { _ in
                                if activeCardIndex == nil {
                                    activeCardIndex = index
                                }
                            }
                            .onEnded({ (value) in
                                guard case .second(true, let drag?) = value else {
                                    return
                                }
                                    
                                if drag.translation.width < -self.dragAreaThreshold {
                                    print("soundEnabled: \(soundEffectManager.soundEnabled)")
                                    if(soundEffectManager.soundEnabled) {
                                        playSound(sound: "swipe", type: "wav")
                                    }
                                    removeCard(at: index)
                                    self.haptics.notificationOccurred(.success)
                                    activeCardIndex = nil
                                    
                                } else if drag.translation.width > self.dragAreaThreshold {
                                    print("soundEnabled: \(soundEffectManager.soundEnabled)")
                                    if(soundEffectManager.soundEnabled) {
                                        playSound(sound: "swipe", type: "wav")
                                    }
                                    addLikedArticleToUser(swipedArticle: displayedArticles[index])
                                    removeCard(at: index, markAsDisliked: false)
                                    self.haptics.notificationOccurred(.success)
                                    activeCardIndex = nil
                                }
                            })
                        ).transition(self.cardRemovalTransition)
                }
                
            }
            .sheet(item: $selectedArticle, content: {
                SafariView(url: $0.articleURL)
            })
            .onAppear{
                Task{
                    await loadDisplayedArticles()
                }
            }
            .zIndex(1)
            
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.yellow)
                    .scaledToFill()
                    .frame(width:350, height: 550)
                    .clipped()
                    .cornerRadius(24)
                    .overlay(
                        VStack(alignment: .center, spacing: 12){
                            Spacer()
                            Text("You've viewed all available articles for today, check back later for more!")
                                .foregroundStyle(.black)
                                .font(.headline)
                                .fontWeight(.bold)
                                .shadow(radius: 1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Rectangle().fill(Color.white)
                                        .opacity(0.7)
                                )
                                .overlay(
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(height:1),
                                    alignment:.bottom
                                )
                            Text("Thank you for your usage of our app!")
                                .foregroundStyle(.black)
                                .font(.caption)
                                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                                .fontWeight(.bold)
                                .frame(minWidth: 85)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Rectangle().fill(Color.white)
                                        .opacity(0.7)
                                )
                            Spacer()
                        }
                            .frame(minWidth: 280)
                            .padding(.bottom, 50),
                        alignment: .bottom
                    )
                Spacer()
            }
            .zIndex(0)
        }
    }
    
    private func removeCard(at index: Int, markAsDisliked: Bool = true) {
        guard index < displayedArticles.count else { return }
        
        let swipedArticle = displayedArticles[index]
        if markAsDisliked {
            addSwipedArticleToUser(swipedArticle)
        }
        
        displayedArticles.remove(at: index)
        
        if displayedArticles.indices.contains(0) {
            activeArticleVM.activeArticle = displayedArticles.last
        }
    }
    
    private func addSwipedArticleToUser(_ swipedArticle: Article) {
        AppSession.markDismissed(article: swipedArticle)
    }

    private func addLikedArticleToUser(swipedArticle: Article) {
        AppSession.markLiked(article: swipedArticle)
    }
    
    @ViewBuilder
    private var overlayView: some View {
        
        switch articleNewsVM.phase {
        case .empty:
            ProgressView()
        case .success(let articles) where articles.isEmpty:
            EmptyPlaceholderView(text: "No Articles", image: nil)
        case .failure(let error):
            RetryView(text: error.localizedDescription, retryAction: refreshTask)
        default: EmptyView()
        }
    }
    
    private var articles: [Article] {
        if case let .success(articles) = articleNewsVM.phase {
            return Array(articles.prefix(10))
        } else {
            return []
        }
    }
    
    @Sendable
    private func loadTask() async {
        await articleNewsVM.loadArticles()
    }
    
    
    private func refreshTask() {
        DispatchQueue.main.async {
            articleNewsVM.fetchTaskToken = FetchTaskToken(category: articleNewsVM.fetchTaskToken.category, token: Date())
        }
    }

    @MainActor
    private func loadDisplayedArticles() async {
        displayedArticles = []

        let interests = await AppSession.loadInterests()
        let seenArticles = await AppSession.loadSeenArticleIDs()
        let categories = mappedCategories(from: interests)
        let quantityToAdd = max(1, 10 / max(categories.count, 1))

        for category in categories {
            articleNewsVM.fetchTaskToken = FetchTaskToken(category: category, token: Date())
            await loadTask()

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
        activeArticleVM.activeArticle = displayedArticles.last
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
