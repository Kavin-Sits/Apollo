//
//  GuideView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/15/23.
//

import SwiftUI

struct GuideView: View {
    
    @Environment(\.dismiss) var presentationMode
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        ScrollView(content: {
            VStack(alignment: .center, spacing: 20){
                HeaderComponent()
                
                Spacer(minLength: 10)
                
                Text("Get Started!")
                    .fontWeight(.black)
                    .modifier(TitleModifier())
                
                Text("Discover and pick the perfect article for your news daily digest!")
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                
                Spacer(minLength: 10)
                
                VStack(alignment: .leading, spacing: 25, content: {
                    GuideComponent(title: "Like", subtitle: "Swipe Right", description: "Do you like this news? Touch the screen and swipe right. It will be saved to the favorites", icon: "heart.circle")
                    
                    GuideComponent(title: "Dismiss", subtitle: "Swipe Left", description: "Would you rather skip this news? Touch the screen and swipe left. You will no longer see it.", icon: "xmark.circle")
                    
                    GuideComponent(title: "Save", subtitle: "Tap the button", description: "Saving articles will let you come back to them later. Sorted by date and time, saved articles promote easy access.", icon: "checkmark.square")
                })
                
                Spacer(minLength: 10)
                
                Button(action: {
                    self.presentationMode.callAsFunction()
                }, label: {
                    Text("Continue".uppercased())
                        .modifier(ButtonModifier())
                })
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.top, 15)
            .padding(.bottom, 25)
            .padding(.horizontal, 20)
        })
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
    }
}

#Preview {
    GuideView()
}

