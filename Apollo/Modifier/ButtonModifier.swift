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
            .foregroundStyle(.white)
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 50)
            .background(Capsule().fill(Color(red: 83/255, green: 131/255, blue: 236/255)))
    }
}
