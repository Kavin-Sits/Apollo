//
//  FooterView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/15/23.
//

import SwiftUI
struct FooterView: View {
    
    @Binding var showBookingAlert: Bool
    @Binding var showGuideView:Bool
    @Binding var showInfoView:Bool
    @EnvironmentObject var nightModeManager: NightModeManager
    @EnvironmentObject var activeArticleVM: ActiveArticleViewModel
    
    let haptics = UINotificationFeedbackGenerator()
    
    var body: some View {
        HStack(spacing: 14) {
            Button(action: {
                self.haptics.notificationOccurred(.success)
                self.showInfoView.toggle()
            }, label: {
                Image(systemName: "info")
            })
            .buttonStyle(CircleActionButtonStyle())
            .sheet(isPresented: $showInfoView, content: {
                InfoView()
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            })

            Button(action: {
                self.haptics.notificationOccurred(.success)
                self.showBookingAlert.toggle()
                saveArticle()
            }, label: {
                Label("Save Article", systemImage: "bookmark.fill")
            })
            .buttonStyle(FilledActionButtonStyle())

            Button(action: {
                self.haptics.notificationOccurred(.success)
                self.showGuideView.toggle()
            }, label: {
                Image(systemName: "questionmark")
            })
            .buttonStyle(CircleActionButtonStyle())
            .sheet(isPresented: $showGuideView, content: {
                GuideView()
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            })
        }
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        .padding(16)
        .glassPanel()
    }
    
    private func saveArticle() {
        guard let article = activeArticleVM.activeArticle else { return }

        AppSession.saveArticle(article)
    }
}
