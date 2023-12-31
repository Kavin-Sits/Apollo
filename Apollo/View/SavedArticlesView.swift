//
//  SavedArticlesView.swift
//  Apollo
//
//  Created by Srihari Manoj on 11/20/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SavedArticlesView: View {
    @StateObject private var viewModel = SavedArticlesViewModel()
    @State private var selectedArticle: SavedArticle?
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        VStack{
            List{
                ForEach(viewModel.savedArticles){ article in
                    SavedArticleTabView(imageURL: article.imageURL, title: article.title, description: article.description ?? "")
                        .onTapGesture {
                            selectedArticle = article
                        }
                        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
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
            .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            .background(Theme.appColors)
            .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        }
    }
}


#Preview {
    SavedArticlesView()
}
