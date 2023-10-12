//
//  ApolloApp.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI

@main
struct ApolloApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject var articleBookmarkVM = ArticleBookmarkViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            FullNewsView()
                .environmentObject(articleBookmarkVM)
        }
    }
}
