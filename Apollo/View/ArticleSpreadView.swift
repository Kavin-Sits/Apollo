//
//  ArticleSpreadView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/10/23.
//

import SwiftUI

struct ArticleSpreadView: View {
    let articles: [Article]
    @State private var selectedArticle: Article?
    
    var body: some View {
        VStack {
            HeaderView()
            ZStack(alignment: .center, content: {
                ForEach(articles) { article in
                    CardView(article: article).frame(width: 350, height: 400)
                        .onTapGesture {
                            selectedArticle = article
                        }
                }
            }).padding()
                .sheet(item: $selectedArticle, content: {
                    SafariView(url: $0.articleURL)
                })
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        ArticleSpreadView(articles: Article.previewData).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
