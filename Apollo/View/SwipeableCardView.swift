//
//  SwipeableCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore

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
                                    addLikedArticleToUser(swipedArticleId: displayedArticles[index].url)
                                    removeCard(at: index)
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
                    if let userId = Auth.auth().currentUser?.email {
                        let userDocRef = Firestore.firestore().collection("users").document(userId)
                        let userDocument = try? await userDocRef.getDocument()
                        
                        if let userDocument = userDocument, userDocument.exists {
                            let userData = userDocument.data()
                            let interests = userData?["interests"] as? [String] ?? []
                            
                            
                            
                            let quantityToAdd:Int = Int(10/interests.count)
                            
                            for interest in interests {
                                switch(interest){
                                case "Sports":
                                    articleNewsVM.fetchTaskToken = FetchTaskToken(category: Category.sports, token: Date())
                                case "Business":
                                    articleNewsVM.fetchTaskToken = FetchTaskToken(category: Category.business, token: Date())
                                case "Technology":
                                    articleNewsVM.fetchTaskToken = FetchTaskToken(category: Category.technology, token: Date())
                                case "Health and Medicine":
                                    articleNewsVM.fetchTaskToken = FetchTaskToken(category: Category.health, token: Date())
                                case "Entertainment":
                                    articleNewsVM.fetchTaskToken = FetchTaskToken(category: Category.entertainment, token: Date())
                                default:
                                    articleNewsVM.fetchTaskToken = FetchTaskToken(category: Category.general, token: Date())
                                }
                                await loadTask()
                                if case let .success(articles) = articleNewsVM.phase {
                                    
                                    let filteredArticles = articles.filter { $0.url != "https://removed.com" }
                                    
                                    let noRepeatArticles = filteredArticles.filter { article in !displayedArticles.contains {$0.url == article.url}
                                    }
                                    var categoryArticles = Array(noRepeatArticles.prefix(quantityToAdd))
                                    
                                    guard let userId = Auth.auth().currentUser?.email else { return }
                                    
                                    let userDocRef = Firestore.firestore().collection("users").document(userId)
                                    let userDocument = try? await userDocRef.getDocument()
                                    
                                    if let userDocument = userDocument, userDocument.exists {
                                        let userData = userDocument.data()
                                        let seenArticles = userData?["seenArticles"] as? [String] ?? []
                                        
                                        categoryArticles = categoryArticles.filter { !seenArticles.contains($0.id)}
                                        
                                        displayedArticles.append(contentsOf: Array(categoryArticles.prefix(quantityToAdd)))
                                        
                                        displayedArticles.shuffle()
                                        
                                        if displayedArticles.indices.contains(0) {
                                            activeArticleVM.activeArticle = displayedArticles.last
                                        }
                                    } else {
                                        print("user does not exist")
                                    }
                                    
                                }
                            }
                        }
                    }
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
    
    private func removeCard(at index: Int) {
        guard index < displayedArticles.count else { return }
        
        let swipedArticle = displayedArticles[index]
        addSwipedArticleToUser(swipedArticleId: swipedArticle.url)
        
        displayedArticles.remove(at: index)
        
        if displayedArticles.indices.contains(0) {
            activeArticleVM.activeArticle = displayedArticles.last
        }
    }
    
    private func addSwipedArticleToUser(swipedArticleId: String) {
        guard let userId = Auth.auth().currentUser?.email else { return }
        
        Firestore.firestore().collection("users").document(userId).updateData(["seenArticles": FieldValue.arrayUnion([swipedArticleId])]) { error in
            if let error = error {
                print("Error adding article: \(error)")
            } else {
                print("Swiped article successfully added!")
            }
        }
                                                           
        let userDocRef = Firestore.firestore().collection("users").document(userId)
        userDocRef.updateData([
            "seenArticles": FieldValue.arrayUnion([swipedArticleId])
        ])
    }
    
    private func addLikedArticleToUser(swipedArticleId: String) {
        guard let userId = Auth.auth().currentUser?.email else { return }
        
        Firestore.firestore().collection("users").document(userId).updateData(["likedArticles": FieldValue.arrayUnion([swipedArticleId])]) { error in
            if let error = error {
                print("Error adding article: \(error)")
            } else {
                print("Liked article successfully added!")
            }
        }
                                                           
        let userDocRef = Firestore.firestore().collection("users").document(userId)
        userDocRef.updateData([
            "likedArticles": FieldValue.arrayUnion([swipedArticleId])
        ])
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
    SwipeableCardView()
}
