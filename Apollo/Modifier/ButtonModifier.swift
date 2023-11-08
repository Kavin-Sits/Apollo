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
            .frame(height: 50)
            .background(Capsule().fill(Color.white))
    }
}
