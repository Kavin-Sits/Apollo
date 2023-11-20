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
        VStack {
            HeaderView(showSettingsView: $showSettings)
                .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            
            Spacer()
            
            SwipeableCardView()
                .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                .environmentObject(activeArticleVM)
            
            Spacer()
            
            FooterView(showBookingAlert: $showAlert, showGuideView: $showGuide , showInfoView: $showInfo)
                .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                .environmentObject(activeArticleVM)
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("SUCCESS"),
            message: Text("Saved this article"),
                  dismissButton: .default(Text("Happy Reading!")))
        })
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .background(Color(red: 224/255, green: 211/255, blue: 175/255))
    }
}

#Preview {
    HomeView()
}
