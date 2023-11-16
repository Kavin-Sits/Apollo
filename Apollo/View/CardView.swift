//
//  CardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/10/23.
//

import SwiftUI

struct CardView: View, Identifiable {
    
    let id = UUID()
    
    let article: Article
    
    var body: some View {
        VStack{
            AsyncImage(url: article.imageURL){ phase in
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
                    Rectangle()
                        .fill(Color.gray)
                        .overlay(
                            HStack{
                                Spacer()
                                Image(systemName: "photo")
                                    .imageScale(.large)
                                Spacer()
                    })
                @unknown default:
                    fatalError()
                }
            }
                .scaledToFill()
                .frame(width:350, height: 550)
                .clipped()
                .cornerRadius(24)
                .overlay(
                    VStack(alignment: .center, spacing: 12){
                        Text(article.title)
                            .foregroundStyle(.black)
                            .font(.headline)
                            .fontWeight(.bold)
                            .shadow(radius: 1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Rectangle().fill(Color.white)
                                    .opacity(0.7)
                            )
                            .overlay(
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(height:1),
                                alignment:.bottom
                            )
                        Text(article.descriptionText)
                            .foregroundStyle(.black)
                            .font(.caption)
                            .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                            .fontWeight(.bold)
                            .frame(minWidth: 85)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Rectangle().fill(Color.white)
                                    .opacity(0.7)
                            )
                        
                        
                        Text(article.captionText)
                            .foregroundStyle(.black)
                            .font(.caption)
                            .background(
                                Rectangle().fill(Color.white)
                                    .opacity(0.7)
                            )
                    }
                        .frame(minWidth: 280)
                        .padding(.bottom, 50),
                    alignment: .bottom
                )
        }
    }
}

#Preview {
    CardView(article: .previewData[0])
}
