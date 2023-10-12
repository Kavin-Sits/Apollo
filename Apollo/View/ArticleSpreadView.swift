//
//  ArticleSpreadView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/10/23.
//

import SwiftUI

struct ArticleSpreadView: View {
    
    @EnvironmentObject var articleBookmarkVM: ArticleBookmarkViewModel
    
    let articles: [Article]
    @State private var selectedArticle: Article?
    
    var body: some View {
        VStack {
            List {
                ForEach(articles) { article in
                    CardView(article: article)
                        .onTapGesture {
                            selectedArticle = article
                        }
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .sheet(item: $selectedArticle, content: {
                SafariView(url: $0.articleURL)
            })
        }
    }
}

struct ArticleSpreadView_Previews: PreviewProvider {
    
    @StateObject static var articleBookmarkVM = ArticleBookmarkViewModel()
    
    static var previews: some View {
        NavigationView {
            ArticleSpreadView(articles: Article.previewData)
                .environmentObject(articleBookmarkVM)
            //.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
