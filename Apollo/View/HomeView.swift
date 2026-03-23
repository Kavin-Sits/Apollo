//
//  HomeView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/8/23.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var activeArticleVM = ActiveArticleViewModel()
    @State var showSettings:Bool = false
    @State var showAlert:Bool = false
    @State var showGuide:Bool = false
    @State var showInfo:Bool = false
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 22) {
                HeaderView(showSettingsView: $showSettings)
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)

                SwipeableCardView()
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                    .environmentObject(activeArticleVM)

                FooterView(showBookingAlert: $showAlert, showGuideView: $showGuide , showInfoView: $showInfo)
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                    .environmentObject(activeArticleVM)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("SUCCESS"),
            message: Text("Saved this article"),
                  dismissButton: .default(Text("Happy Reading!")))
        })
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
    }
}

#Preview {
    HomeView()
}
