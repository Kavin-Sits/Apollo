//
//  SavedArticlesViewModel.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/20/23.
//

import SwiftUI


class SavedArticlesViewModel: ObservableObject {
    @Published var savedArticles: [SavedArticle] = []

    @MainActor
    func fetchSavedArticles() async {
        savedArticles = await AppSession.loadSavedArticles()
    }
}
