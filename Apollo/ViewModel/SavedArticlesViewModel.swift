//
//  SavedArticlesViewModel.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/20/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore


class SavedArticlesViewModel: ObservableObject {
    @Published var savedArticles: [SavedArticle] = []

    func fetchSavedArticles(userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { (document, error) in
            guard let document = document, document.exists, let userData = document.data() else {
                print("Document does not exist")
                return
            }

            let articleIds = userData["savedArticles"] as? [String] ?? []
            self.fetchArticles(articleIds: articleIds)
        }
    }

    private func fetchArticles(articleIds: [String]) {
        let group = DispatchGroup()
        savedArticles = []

        for articleId in articleIds {
            group.enter()
            Firestore.firestore().collection("articles").document(articleId).getDocument { (document, error) in
                defer { group.leave() }
                if let document = document, document.exists, let articleData = document.data() {
                    // Assuming you have an initializer for Article from a dictionary
                    if let article = self.createArticle(from: articleData) {
                        self.savedArticles.append(article)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            // Update the UI or perform any further actions
            // once all articles are fetched
        }
    }
    
    private func createArticle(from data: [String: Any]) -> SavedArticle? {
        let title = data["title"] as? String ?? ""
        let url = data["url"] as? String ?? ""
        let description = data["description"] as? String ?? ""
        let urlToImage = data["urlToImage"] as? String ?? ""

        return SavedArticle(title: title, url: url, description: description, urlToImage: urlToImage)
    }
}
