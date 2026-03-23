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
