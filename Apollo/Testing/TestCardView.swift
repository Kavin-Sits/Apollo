//
//  TestCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/19/23.
//

import SwiftUI

struct TestCardView: View {
    
    @StateObject var articleNewsVM = ArticleNewsViewModel()
    @GestureState private var dragState = DragState.inactive
    @State private var cardRemovalTransition = AnyTransition.trailingBottom
    @State private var activeCardIndex: Int? = nil
    @State private var displayedArticles: [Article] = []
    @State private var selectedArticle: Article?
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
            ForEach(displayedArticles.indices, id: \.self){ index in
                CardView(article: displayedArticles[index])
                    .onTapGesture {
                        selectedArticle = displayedArticles[index]
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
                                playSound(sound: "swipe", type: "wav")
                                removeCard(at: index)
                                activeCardIndex = nil
                                
                            } else if drag.translation.width > self.dragAreaThreshold {
                                playSound(sound: "swipe", type: "wav")
                                removeCard(at: index)
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
                await loadTask()
                if case let .success(articles) = articleNewsVM.phase {
                    displayedArticles = Array(articles.prefix(10))
                }
            }
        }
    }
    
    private func removeCard(at index: Int) {
        guard index < displayedArticles.count else { return }
        displayedArticles.remove(at: index)
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
