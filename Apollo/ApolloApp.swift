//
//  ApolloApp.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ApolloApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared

    @StateObject var articleBookmarkVM = ArticleBookmarkViewModel()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//            FullNewsView()
//                .environmentObject(articleBookmarkVM)
        }
    }
}
