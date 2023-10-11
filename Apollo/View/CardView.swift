//
//  CardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import Foundation
import SwiftUI

struct CardView: View {
    
    let article: Article
//    let newsImg: String
//    let title: String
//    let subTitle: String
    
    var body: some View {
        VStack {
            AsyncImage(url: article.imageURL){
                phase in
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
                        .aspectRatio(contentMode: .fit)
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
            .frame(width:350, height: 175)
            .background(Color.white)
            .clipped()
            
            VStack(alignment: .leading, spacing: 8, content: {
                Text(article.title)
                    .font(.headline)
                
                Text(article.descriptionText)
                    .font(.subheadline)
            })
            .padding([.horizontal, .bottom])
            
            HStack{
                Text(article.captionText)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .cornerRadius(24)
        .background()
        /*Image(newsImg)
            .resizable()
            .scaledToFill()
            .frame(width:350, height: 650)
            .clipped()
            .cornerRadius(24)
            .overlay(
                VStack(alignment: .center, spacing: 12){
                    Text(title)
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.bold)
                        .shadow(radius: 1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .overlay(
                            Rectangle()
                                .fill(Color.white)
                                .frame(height:1),
                            alignment:.bottom
                        )
                    Text(subTitle)
                        .foregroundColor(.black)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(minWidth: 85)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Rectangle().fill(Color.white)
                                .opacity(0.7)
                        )
                }
                    .frame(minWidth: 280)
                    .padding(.bottom, 50),
                alignment: .bottom
            )*/
    }
}

#Preview {
    NavigationStack{
        List{
            CardView(article: .previewData[0])
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
//    CardView(article: .previewData[0]).previewLayout(.fixed(width: 375, height: 600)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
