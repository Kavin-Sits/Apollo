//
//  TestCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/10/23.
//

import SwiftUI

struct TestCardView: View {
    
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
//                        .zIndex(article.url == topArticleURL ? 1 : 0)
                }
            }
        }
        .sheet(item: $selectedArticle, content: {
            SafariView(url: $0.articleURL)
        })
//        .onAppear{
//            updateTopArticle()
//            Task{
//                await loadTask()
//            }
//        }
    }
    
    private func updateTopArticle() {
        topArticleURL = articles.first(
            where: { !tappedArticles.contains($0.url) })?.url
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
    TestCardView()
}
