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

    @StateObject var nightModeManager = NightModeManager()
    @StateObject var articleBookmarkVM = ArticleBookmarkViewModel()
    
    var body: some Scene {
        WindowGroup {
//            NavigationView {
//                LoginView()
//                    .environmentObject(nightModeManager) // Inject nightModeManager as an environment object
//                MainSettingsView()
//                    .environmentObject(nightModeManager)
//                    .navigationBarTitle("Settings")
//                TestView()
//                    .environmentObject(nightModeManager)
//                CreateAccountView()
//                    .environmentObject(nightModeManager)
//                LoginView()
//                    .environmentObject(nightModeManager)
//                HeaderView()
//                    .environmentObject(nightModeManager)
////                OldCardView()
////                    .environmentObject(nightModeManager)
//            }
//            .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
//            .onAppear {
//                        nightModeManager.isNightMode = UserDefaults.standard.bool(forKey: "nightModeEnabled")
//            }
            LoginView()
                .environmentObject(nightModeManager) // Inject nightModeManager as an environment object
                .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                .onAppear {
                    nightModeManager.isNightMode = UserDefaults.standard.bool(forKey: "nightModeEnabled")
                }
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//            FullNewsView()
//                .environmentObject(articleBookmarkVM)
        }
    }
}

