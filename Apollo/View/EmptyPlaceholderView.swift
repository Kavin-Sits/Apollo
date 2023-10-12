//
//  EmptyPlaceholderView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/11/23.
//

import SwiftUI

struct EmptyPlaceholderView: View {
    let text: String
    let image: Image?
    
    var body: some View {
        VStack(spacing: 0){
            Spacer()
            if let image = self.image {
                image
                    .imageScale(.large)
                    .font(.system(size:52))
            }
            Text(text)
            Spacer()
        }
    }
}

#Preview {
    EmptyPlaceholderView(text:"No Bookmarks", image: Image(systemName: "bookmark"))
}
