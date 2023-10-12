//
//  FullNewsView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/11/23.
//

import SwiftUI

struct FullNewsView: View {
    var body: some View {
        TabView {
            NewsTabView()
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }
            
            BookmarkTabView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
        }
    }
}

struct FullNewsView_Previews: PreviewProvider {
    
    static var previews: some View {
        FullNewsView()
    }
    
}
