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
    
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: article.imageURL){ phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(ProgressView().tint(.white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        AppStyle.heroGradient
                            .overlay(
                                Image(systemName: "newspaper.fill")
                                    .font(.system(size: 46))
                                    .foregroundStyle(Color.white.opacity(0.65))
                            )
                    @unknown default:
                        Rectangle().fill(Color.gray)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            AppStyle.articleOverlayTop,
                            AppStyle.articleOverlayMiddle,
                            AppStyle.articleOverlayBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(article.source.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(AppStyle.heroTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.white.opacity(0.14)))

                        Spacer()

                        Text(article.captionText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppStyle.heroTextSecondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(article.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppStyle.heroTextPrimary)
                            .lineLimit(4)

                        if !article.descriptionText.isEmpty {
                            Text(article.descriptionText)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(AppStyle.heroTextSecondary)
                                .lineLimit(3)
                        }
                    }

                    if !article.authorText.isEmpty {
                        Text("By \(article.authorText)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppStyle.heroTextPrimary.opacity(0.9))
                    }
                }
                .padding(22)
            }
            .background(AppStyle.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.black.opacity(0.22), radius: 24, x: 0, y: 16)
        }
    }
}

#Preview {
    CardView(article: .previewData[0])
}
