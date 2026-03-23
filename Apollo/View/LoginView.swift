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
    
    let backgroundColor = Color(red: 224/255, green: 211/255, blue: 175/255)
    
    var body: some View {
        if authViewModel.isLoggedIn {
            if shouldShowInterestSelection {
                InterestSelectionView(email: AppSession.currentUserID ?? AppSession.guestUserID)
                    .onAppear() {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) {
                            (granted,error) in
                            if granted {
                                notifAuthorization = true
                            }
                            else if let error = error {
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
        
        NavigationStack{
            VStack{
                VStack(alignment: .center, spacing: 25) {
                    Text("APOLLO")
                        .font(Font.custom("Bodoni 72 Smallcaps", size: 52))
                    
                    VStack(alignment: .leading) {
                        Text("Username/Email")
                        TextField("username", text: $authViewModel.username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .padding(.top, 10)
                        Text("Password")
                            .padding(.top, 10)
                        SecureField("password", text: $authViewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.top, 10)
                        NavigationLink("Forgot password") {
                            ForgotPasswordView()
                                .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
//                                .onAppear {
//                                    nightModeManager.isNightMode = UserDefaults.standard.bool(forKey: "nightModeEnabled")
//                                }
                        }
                        .controlSize(.small)
                    }
                    
                    Button {
                        Task {
                            await loginUser()
                        }
                    } label: {
                        Text("Login")
                            .modifier(ButtonModifier())
                    }
                    
                    Text("or")
                    
                    NavigationLink{
                        CreateAccountView(userSelectedInterests: self.$shouldShowInterestSelection)
                            .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                    } label: {
                        Text("Create account")
                            .modifier(ButtonModifier())
                    }

                    Text("or")

                    Button {
                        AppSession.startGuestSession()
                        authViewModel.logIn()
                        shouldShowInterestSelection = false
                    } label: {
                        Text("Continue as Guest")
                            .modifier(ButtonModifier())
                    }

                    Spacer()
                    
                }
                .padding(.top, 50)
                .frame(width: 300)
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
            }
            .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity)
            .background(Theme.appColors)
            .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
            .alert("Unable to Sign In", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
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
