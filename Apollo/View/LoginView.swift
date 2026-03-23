//
//  LoginView.swift
//  Apollo
//
//  Created by Andy Hsu on 10/13/23.
//

import SwiftUI
import UserNotifications

public var notifAuthorization = false

extension UIApplication {

    @MainActor
    class func getTopViewController(base: UIViewController? = nil) -> UIViewController? {

        let base = base ?? UIApplication.shared.keyWindow?.rootViewController
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var nightModeManager: NightModeManager
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var shouldShowInterestSelection = false

    var body: some View {
        if authViewModel.isLoggedIn {
            if shouldShowInterestSelection {
                InterestSelectionView(email: AppSession.currentUserID ?? AppSession.guestUserID) {
                    shouldShowInterestSelection = false
                }
                    .onAppear {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                            if granted {
                                notifAuthorization = true
                            } else if let error {
                                print(error.localizedDescription)
                            }
                        }
                    }
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            } else {
                HomeView()
                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            }
        } else {
            content
        }
    }

    var content: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionEyebrow(text: "Swipeable News")

                            Text("APOLLO")
                                .font(Font.custom("Bodoni 72 Smallcaps", size: 54))
                                .foregroundStyle(AppStyle.surfaceTextPrimary)

                            Text("A cleaner daily briefing experience with swipeable stories that adapts to what you actually read.")
                                .font(.system(.title3, design: .rounded).weight(.medium))
                                .foregroundStyle(AppStyle.surfaceTextSecondary)

                            HStack(spacing: 12) {
                                landingStat(title: "Swipe", subtitle: "Save or skip in seconds")
                                landingStat(title: "Learn", subtitle: "Interests sharpen over time")
                            }
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            Text("Welcome back")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(AppStyle.surfaceTextPrimary)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Username or email")
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppStyle.surfaceTextSecondary)

                                TextField("name@example.com", text: $authViewModel.username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(.horizontal, 16)
                                    .frame(height: 54)
                                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.94)))
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Password")
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppStyle.surfaceTextSecondary)

                                SecureField("Enter password", text: $authViewModel.password)
                                    .padding(.horizontal, 16)
                                    .frame(height: 54)
                                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.94)))
                            }

                            NavigationLink("Forgot password?") {
                                ForgotPasswordView()
                                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                            }
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppStyle.surfaceTextSecondary)

                            Button {
                                Task {
                                    await loginUser()
                                }
                            } label: {
                                Text("Log In")
                            }
                            .buttonStyle(FilledActionButtonStyle())

                            NavigationLink {
                                CreateAccountView(userSelectedInterests: self.$shouldShowInterestSelection)
                                    .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                            } label: {
                                Text("Create account")
                            }
                            .buttonStyle(OutlineActionButtonStyle())

                            Button {
                                AppSession.startGuestSession()
                                authViewModel.logIn()
                                shouldShowInterestSelection = false
                            } label: {
                                Text("Continue as Guest")
                            }
                            .buttonStyle(OutlineActionButtonStyle())
                        }
                        .padding(24)
                        .glassPanel()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    .padding(.bottom, 24)
                }
            }
            .onAppear {
                if AppSession.isGuestModeEnabled {
                    authViewModel.logIn()
                    shouldShowInterestSelection = false
                }

                if AppSession.hasAuthenticatedUser {
                    AppSession.endGuestSession()
                    shouldShowInterestSelection = false
                    authViewModel.logIn()
                }
            }
            .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
            .alert("Unable to Sign In", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func landingStat(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(AppStyle.surfaceTextPrimary)

            Text(subtitle)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(AppStyle.surfaceTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel()
    }

    private func loginUser() async {
        do {
            try await AppSession.signIn(email: authViewModel.username, password: authViewModel.password)
            await MainActor.run {
                alertMessage = ""
                shouldShowInterestSelection = false
                authViewModel.logIn()
            }
        } catch {
            await MainActor.run {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

//#Preview {
//    LoginView()
//}
