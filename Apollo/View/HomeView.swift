//
//  HomeView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/8/23.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var showSettings:Bool = false
    
    var body: some View {
        VStack {
            HeaderView(showSettingsView: $showSettings)
            
            Spacer()
            
            SwipeableCardView(articles: Article.previewData)
        }
    }
}

#Preview {
    HomeView()
}
