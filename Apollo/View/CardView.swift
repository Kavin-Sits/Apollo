//
//  CardView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import Foundation
import SwiftUI

struct CardView: View {
    var body: some View {
        Image(.bidenPhoto)
            .resizable()
            .scaledToFill()
            .frame(width:350, height: 650)
            .clipped()
            .cornerRadius(24)
            .overlay(
                VStack(alignment: .center, spacing: 12){
                    Text("How Biden’s Promises to Reverse Trump’s Immigration Policies Crumbled")
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
                    Text("President Biden has tried to contain a surge of migration by embracing, or at least tolerating, some of his predecessor’s approaches.")
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

#Preview {
    
    CardView().previewLayout(.fixed(width: 375, height: 600)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
