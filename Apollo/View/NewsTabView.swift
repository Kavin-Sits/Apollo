//
//  NewsTabView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/10/23.
//

import SwiftUI

struct NewsTabView: View {
    
    @StateObject var articleNewsVM = ArticleNewsViewModel()
    
    var body: some View {
        NavigationView{
            ArticleSpreadView(articles: articles)
                .navigationTitle(articleNewsVM.selectedCategory.text)
        }
    }
    
    private var articles: [Article] {
        if case let .success(articles) = articleNewsVM.phase {
            return articles
        }
        else{
            return []
        }
    }
}

#Preview {
    NewsTabView(articleNewsVM: ArticleNewsViewModel(articles: Article.previewData))
}
