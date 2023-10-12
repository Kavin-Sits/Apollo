//
//  SwiftUIView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/11/23.
//

import SwiftUI

struct BookmarkTabView: View {
    
    @EnvironmentObject var articleBookmarkVM: ArticleBookmarkViewModel
    
    var body: some View {
        NavigationView(){
            ArticleSpreadView(articles: articleBookmarkVM.bookmarks)
                .overlay(overlayView(isEmpty: articleBookmarkVM.bookmarks.isEmpty))
                .navigationTitle("Saved Articles")
        }
    }
    
    @ViewBuilder
    func overlayView(isEmpty: Bool) -> some View {
        if isEmpty {
            EmptyPlaceholderView(text: "No saved articles", image: Image(systemName: "bookmark"))
        }
    }
}

struct BookmarkTabView_Previews: PreviewProvider {
    @StateObject static var articleBookmarkVM = ArticleBookmarkViewModel()
    
    static var previews: some View {
        BookmarkTabView()
            .environmentObject(articleBookmarkVM)
    }
    
}

/*#Preview {
    BookmarkTabView()
}*/
