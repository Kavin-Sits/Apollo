//
//  TestHomeView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/10/23.
//

import SwiftUI

struct TestHomeView: View {
    
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
    TestHomeView()
}
