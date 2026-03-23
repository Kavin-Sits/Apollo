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
        HStack{
            Button(action: {
                self.haptics.notificationOccurred(.success)
                self.showInfoView.toggle()
            }, label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 24, weight: .regular))
            })
            .tint(Color.primary)
            .sheet(isPresented: $showInfoView, content: {
                InfoView()
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            })
            
            Spacer()
            
            Button(action: {
                self.haptics.notificationOccurred(.success)
                self.showBookingAlert.toggle()
                saveArticle()
            }, label: {
                Text("Save News Article".uppercased())
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.heavy)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 22)
                    .tint(Color.pink)
                    .background(
                        Capsule().stroke(Color.pink, lineWidth: 2)
                    )
            })
            
            Spacer()
            
            Button(action: {
                self.haptics.notificationOccurred(.success)
                self.showGuideView.toggle()
            }, label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 24, weight: .regular))
            })
            .tint(Color.primary)
            .sheet(isPresented: $showGuideView, content: {
                GuideView()
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            })
        }
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        .padding()
    }
    
    private func saveArticle() {
        guard let article = activeArticleVM.activeArticle else { return }

        AppSession.saveArticle(article)
    }
}
