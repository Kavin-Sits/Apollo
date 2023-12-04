//
//  MiscTesting.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 12/3/23.
//

import SwiftUI

struct MiscTesting: View {
    var body: some View {
        
        Image(systemName: "person.circle")
            .resizable()
            .scaledToFill()
            .frame(width: UIScreen.main.bounds.width / 10, height: UIScreen.main.bounds.width / 10)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1))
            .shadow(radius: 5)
    }
}

#Preview {
    MiscTesting()
}
