//
//  SwipeableCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI
import CoreData

struct SwipeableCardView: View {
    
    let articles: [Article]
    @State private var tappedArticles = Set<String>()
    @State private var topArticleURL: String?
    @State private var selectedArticle: Article?
    @GestureState private var dragState = DragState.inactive
    @State private var cardRemovalTransition = AnyTransition.trailingBottom
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
            ForEach(articles) { article in
                if !tappedArticles.contains(article.url) {
                    CardView(article: article)
                        .onTapGesture {
                            print("tapped")
                            if article.url == topArticleURL {
                                self.selectedArticle = article
                            }
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
                                if article.url == topArticleURL {
                                    switch value {
                                    case .first(true):
                                        state = .pressing
                                    case .second(true, let drag):
                                        state = .dragging(translation: drag?.translation ?? .zero)
                                    default:
                                        break
                                    }
                                }
                            })
                            .onChanged({ (value) in
                                if article.url == topArticleURL {
                                    guard case .second(true, let drag?) = value else {
                                        return
                                    }
                                    
                                    if drag.translation.width < -self.dragAreaThreshold {
                                        self.cardRemovalTransition = AnyTransition.leadingBottom
                                    }
                                    
                                    if drag.translation.width > self.dragAreaThreshold {
                                        self.cardRemovalTransition = AnyTransition.trailingBottom
                                    }
                                }
                            })
                            .onEnded({ (value) in
                                if article.url == topArticleURL {
                                    guard case .second(true, let drag?) = value else {
                                        return
                                    }
                                    
                                    if drag.translation.width < -self.dragAreaThreshold || drag.translation.width > self.dragAreaThreshold {
                                        playSound(sound: "swipe", type: "wav")
                                        tappedArticles.insert(article.url)
                                        updateTopArticle()
                                        
                                    }
                                }
                            })
                        ).transition(self.cardRemovalTransition)
                }
            }
            .sheet(item: $selectedArticle, content: {
                SafariView(url: $0.articleURL)
            })
        }
        .onAppear{
            updateTopArticle()
        }
    }
    
    private func updateTopArticle() {
        topArticleURL = articles.first(
            where: { !tappedArticles.contains($0.url) })?.url
    }
}

#Preview {
    SwipeableCardView(articles: Array(Article.previewData.prefix(10)))
}
