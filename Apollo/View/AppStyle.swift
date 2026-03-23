//
//  AppStyle.swift
//  Apollo
//
//  Created by Codex on 3/22/26.
//

import SwiftUI

enum Theme {
    static var appColors: Color {
        Color("AppColors")
    }
}

enum AppStyle {
    static let backgroundTop = Color(red: 0.95, green: 0.90, blue: 0.78)
    static let backgroundBottom = Color(red: 0.86, green: 0.76, blue: 0.59)
    static let cardTop = Color(red: 0.15, green: 0.19, blue: 0.27)
    static let cardBottom = Color(red: 0.05, green: 0.08, blue: 0.14)
    static let accent = Color(red: 0.94, green: 0.48, blue: 0.35)
    static let accentSecondary = Color(red: 0.98, green: 0.78, blue: 0.44)
    static let surfaceTextPrimary = Color(red: 0.14, green: 0.12, blue: 0.11)
    static let surfaceTextSecondary = Color(red: 0.26, green: 0.23, blue: 0.20).opacity(0.82)
    static let heroTextPrimary = Color.white
    static let heroTextSecondary = Color.white.opacity(0.76)
    static let panelFill = Color.white.opacity(0.56)
    static let panelStroke = Color.black.opacity(0.08)
    static let articleOverlayTop = Color.black.opacity(0.18)
    static let articleOverlayMiddle = Color.black.opacity(0.42)
    static let articleOverlayBottom = Color.black.opacity(0.88)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, Theme.appColors, backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [cardTop, Color(red: 0.09, green: 0.12, blue: 0.19), cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppStyle.backgroundGradient
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 12)
                .offset(x: 150, y: -260)
            Circle()
                .fill(AppStyle.accent.opacity(0.24))
                .frame(width: 280, height: 280)
                .blur(radius: 28)
                .offset(x: -140, y: 240)
        }
        .ignoresSafeArea()
    }
}

struct GlassPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppStyle.panelFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppStyle.panelStroke, lineWidth: 1)
            )
    }
}

extension View {
    func glassPanel() -> some View {
        modifier(GlassPanelModifier())
    }
}

struct SectionEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .tracking(1.3)
            .foregroundStyle(AppStyle.surfaceTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.78)))
    }
}

struct FilledActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct OutlineActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppStyle.surfaceTextPrimary)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.68))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct CircleActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(AppStyle.surfaceTextPrimary)
            .frame(width: 56, height: 56)
            .background(Circle().fill(Color.white.opacity(0.68)))
            .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
