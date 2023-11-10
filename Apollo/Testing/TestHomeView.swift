//
//  TestHomeView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/10/23.
//

import SwiftUI

struct TestHomeView: View {
    
    @StateObject var articleNewsVM = ArticleNewsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var showSettings:Bool = false
    
    var body: some View {
        VStack {
//            HeaderView(showSettingsView: $showSettings)
            
//            Spacer()
            
//            SwipeableCardView(articles: Array(/*Article.previewData.prefix(10)*/articles.prefix(10)))
//                .task(id: articleNewsVM.fetchTaskToken, loadTask)
            
            
        }
//        .onAppear{
//            Task{
//                await loadTask()
//            }
//        }
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
            return articles
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
    TestHomeView()
}
