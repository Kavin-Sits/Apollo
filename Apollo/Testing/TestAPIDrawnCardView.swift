//
//  TestCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/10/23.
//

import SwiftUI

struct TestAPIDrawnCardView: View {
    
    @StateObject var articleNewsVM = ArticleNewsViewModel()
    @State private var tappedArticles = Set<String>()
    @State private var topArticleURL: String?
    @GestureState private var dragState = DragState.inactive
    @State private var cardRemovalTransition = AnyTransition.trailingBottom
    var dragAreaThreshold: CGFloat = 65.0
    @State private var selectedArticle: Article?
    
    
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
            ForEach(articles) { article in
                if !tappedArticles.contains(article.url) {
                    CardView(article: article)
                        .onTapGesture {
                            selectedArticle = article
                        }
                        .zIndex(article.url == topArticleURL ? 1 : 0)
                        .overlay(
                            ZStack{
                                Image(systemName: "x.circle")
                                    .modifier(SymbolModifier())
                                    .opacity(article.url == topArticleURL && self.dragState.translation.width < -self.dragAreaThreshold ? 1.0 : 0.0)
                                
                                Image(systemName: "heart.circle")
                                    .modifier(SymbolModifier())
                                    .opacity(article.url == topArticleURL && self.dragState.translation.width > self.dragAreaThreshold ? 1.0 : 0.0)
                            })
                        .offset(x: article.url == topArticleURL ? self.dragState.translation.width : 0, y: article.url == topArticleURL ? self.dragState.translation.height : 0)
                        .scaleEffect(self.dragState.isDragging && article.url == topArticleURL ? 0.85 : 1.0)
                        .rotationEffect(Angle(degrees: article.url == topArticleURL ? Double(self.dragState.translation.width / 12) : 0))
                        .animation(.interpolatingSpring(stiffness: 120, damping: 120), value: dragState.isDragging)
                        .gesture(LongPressGesture(minimumDuration: 0.01)
                            .sequenced(before: DragGesture())
                            .updating(self.$dragState, body: { (value, state, transaction) in
                                switch value {
                                case .first(true):
                                    state = .pressing
                                case .second(true, let drag):
                                    state = .dragging(translation: drag?.translation ?? .zero)
                                default:
                                    break
                                }
                            })
                            .onChanged({ (value) in
                                guard case .second(true, let drag?) = value else {
                                    return
                                }
                                
                                if drag.translation.width < -self.dragAreaThreshold {
                                    self.cardRemovalTransition = AnyTransition.leadingBottom
                                }
                                
                                if drag.translation.width > self.dragAreaThreshold {
                                    self.cardRemovalTransition = AnyTransition.trailingBottom
                                }
                            })
                            .onEnded({ (value) in
                                    guard case .second(true, let drag?) = value else {
                                        return
                                    }
                                    
                                if drag.translation.width < -self.dragAreaThreshold {
                                    playSound(sound: "swipe", type: "wav")
                                    tappedArticles.insert(article.url)
                                    updateTopArticle()
                                    
                                } else if drag.translation.width > self.dragAreaThreshold {
                                    playSound(sound: "swipe", type: "wav")
                                    tappedArticles.insert(article.url)
                                    updateTopArticle()
                                    
                                }
                            })
                        ).transition(self.cardRemovalTransition)
                }
            }
        }
        .sheet(item: $selectedArticle, content: {
            SafariView(url: $0.articleURL)
        })
        .onAppear{
            updateTopArticle()
            Task{
                await loadTask()
            }
        }
    }
    
    private func updateTopArticle() {
        if let currentTopIndex = articles.firstIndex(where: { $0.url == topArticleURL }) {
                // Find the next article in the list that hasn't been tapped
                let nextArticle = articles[(currentTopIndex + 1)...].first { !tappedArticles.contains($0.url) }
                topArticleURL = nextArticle?.url
            } else {
                // If no current top article, pick the first one in the list
                topArticleURL = articles.first(where: { !tappedArticles.contains($0.url) })?.url
            }
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
}

#Preview {
    TestAPIDrawnCardView()
}
