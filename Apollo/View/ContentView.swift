//
//  ContentView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    let articles: [Article]
    @State private var selectedArticle: Article?
    @GestureState private var dragState = DragState.inactive
    @State private var cardRemovalTransition = AnyTransition.trailingBottom
    var dragAreaThreshold: CGFloat = 65.0
    @State var currentIndex = 0
    @State var cardViews: [CardView] = []
    @State private var lastCardIndex: Int = 1
    @State var showSettings:Bool = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    init(articles: [Article]) {
            self.articles = articles

            // Initializing cardViews here
            var views = [CardView]()
            for index in 0..<min(10, articles.count) {
                views.append(CardView(article: articles[index]))
            }
            self.cardViews = views
        }
    
    private func moveCards(){
        cardViews.removeFirst()
    }
    
    private func isTopCard(cardView: CardView) -> Bool {
        guard let index = cardViews.firstIndex(where: { $0.id == cardView.id }) else {
            return false
        }
        return index == 0
    }
    
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
        
        VStack {
            HeaderView(showSettingsView: $showSettings)
            
            Spacer()
            
            ZStack {
                ForEach(0..<10) { index in
                    let article = articles[index]
                    CardView(article: article)
                        .onTapGesture {
                            selectedArticle = article
                        }
                        .zIndex(index == currentIndex ? 1 : 0)
                        .overlay(
                            ZStack{
                                Image(systemName: "x.circle")
                                    .modifier(SymbolModifier())
                                    .opacity(index == currentIndex && self.dragState.translation.width < -self.dragAreaThreshold ? 1.0 : 0.0)
                                
                                Image(systemName: "heart.circle")
                                    .modifier(SymbolModifier())
                                    .opacity(index == currentIndex && self.dragState.translation.width > self.dragAreaThreshold ? 1.0 : 0.0)
                            })
                        .offset(x: index == currentIndex ? self.dragState.translation.width : 0, y: index == currentIndex ? self.dragState.translation.height : 0)
                        .scaleEffect(self.dragState.isDragging && index == currentIndex ? 0.85 : 1.0)
                        .rotationEffect(Angle(degrees: index == currentIndex ? Double(self.dragState.translation.width / 12) : 0))
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
                                    
                                    if drag.translation.width < -self.dragAreaThreshold || drag.translation.width > self.dragAreaThreshold {
                                        playSound(sound: "swipe", type: "wav")
                                        currentIndex += 1
                                    }
                                })
                        ).transition(self.cardRemovalTransition)
                }
                .sheet(item: $selectedArticle, content: {
                    SafariView(url: $0.articleURL)
                })
            }
        }
    }
}

#Preview {
    ContentView(articles: Article.previewData)
}
