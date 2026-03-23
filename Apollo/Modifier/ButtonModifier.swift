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
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppStyle.accent, AppStyle.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: AppStyle.accent.opacity(0.35), radius: 18, x: 0, y: 12)
    }
}
