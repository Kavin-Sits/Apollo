//
//  HeaderComponent.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/15/23.
//

import SwiftUI

struct HeaderComponent: View {
    var body: some View {
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 20, content: {
            Capsule()
                .frame(width: 120, height: 6)
                .foregroundStyle(Color.secondary)
                .opacity(0.2)
            
            Text("Apollo")
                .font(.custom("Bodoni 72 Smallcaps Book", size: 36))
                .tint(Color.primary)
            
        })
    }
}

#Preview {
    HeaderComponent()
}

