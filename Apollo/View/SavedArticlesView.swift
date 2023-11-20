//
//  SavedArticlesView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/20/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SavedArticlesView: View {
    @StateObject private var viewModel = SavedArticlesViewModel()
    @State private var selectedArticle: SavedArticle?
    
    var body: some View {
        VStack{
            List{
                ForEach(viewModel.savedArticles){ article in
                    SavedArticleTabView(imageURL: article.imageURL, title: article.title, description: article.description ?? "")
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
            .onAppear {
                if let userID = Auth.auth().currentUser?.email {
                    viewModel.fetchSavedArticles(userId: userID)
                }
            }
        }
    }
}


#Preview {
    SavedArticlesView()
}
