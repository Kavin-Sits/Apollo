//
//  OldCardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/10/23.
//

import SwiftUI

struct OldCardView: View {
    
    let newsImg:String
    let title: String
    let subTitle: String
    
    var body: some View {
        VStack{
            Image(newsImg)
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
                )
        }
    }
}

#Preview {
    OldCardView(newsImg: "BidenPhoto", title: "How Biden’s Promises to Reverse Trump’s Immigration Policies Crumbled", subTitle: "President Biden has tried to contain a surge of migration by embracing, or at least tolerating, some of his predecessor’s approaches.")
}
