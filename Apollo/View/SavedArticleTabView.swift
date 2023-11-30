//
//  SavedArticleTabView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/20/23.
//

import SwiftUI

struct SavedArticleTabView: View {
    
    let imageURL: URL?
    let title: String
    let description: String
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16, content: {
            AsyncImage(url: imageURL){ phase in
                switch phase {
                case .empty:
                    HStack{
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    HStack{
                        Spacer()
                        Image(systemName: "photo")
                            .imageScale(.large)
                        Spacer()
                    }
                @unknown default:
                    fatalError()
                }
            }
            .frame(minHeight:200, maxHeight: 300)
            .background(Color.gray.opacity(0.3))
                
            VStack(alignment: .leading, spacing: 8, content: {
                Text(title)
                    .font(.headline)
                    .lineLimit(3)
                
                Text(description)
                    .font(.subheadline)
                    .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                
            })
            .padding([.horizontal, .bottom])
                
            })
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
    }
}

#Preview {
    SavedArticleTabView(imageURL: Article.previewData[0].imageURL ?? nil, title: Article.previewData[0].title, description: Article.previewData[0].descriptionText)
}
