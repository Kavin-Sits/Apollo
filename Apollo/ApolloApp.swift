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
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var nightModeManager = NightModeManager()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(authViewModel)
                .environmentObject(nightModeManager) // Inject nightModeManager as an environment object
                .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                .onAppear {
                    nightModeManager.isNightMode = UserDefaults.standard.bool(forKey: "nightModeEnabled")
                }
        }
    }
}
