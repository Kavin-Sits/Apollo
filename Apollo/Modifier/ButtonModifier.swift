//
//  buttonModifier.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/7/23.
//

//

import SwiftUI


struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Capsule().fill(Color.pink))
            .foregroundStyle(Color.white)
    }
}
