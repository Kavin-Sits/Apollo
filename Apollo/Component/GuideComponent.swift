//
//  GuideComponent.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/15/23.
//

import SwiftUI

struct GuideComponent: View {
    var title:String
    var subtitle: String
    var description: String
    var icon: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 20, content: {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(Color.pink)
            
                VStack(alignment: .leading, spacing: 4, content: {
                    HStack {
                        Text(title.uppercased())
                            .font(.title)
                        .fontWeight(.heavy)
                        
                        Spacer()
                        
                        Text(subtitle.uppercased())
                            .font(.footnote)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color.pink)
                    }
                    Divider().padding(.bottom, 4)
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                })
        })
    }
}

#Preview {
    GuideComponent(
        title: "Title",
        subtitle: "Swipe right",
        description: "This is a placeholder sentence. ",
        icon: "heart.circle"
    )
        .previewLayout(.sizeThatFits)
}
