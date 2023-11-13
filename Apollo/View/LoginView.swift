//
//  LoginView.swift
//  Apollo
//
//  Created by Andy Hsu on 10/13/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import UserNotifications
import GoogleSignIn
import GoogleSignInSwift

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
    @State private var errorMessage = ""
    @State private var userInterests: [String] = []
    @State private var userSelectedInterests: Bool = true
    
    let backgroundColor = Color(red: 148/255, green: 172/255, blue: 255/255)
    
    var body: some View {
        if authViewModel.isLoggedIn {
            if !userSelectedInterests {
                InterestSelectionView(email: (Auth.auth().currentUser?.email)!)
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
            } else {
                HomeView()
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
                    
                    Text(errorMessage)
                        .foregroundStyle(.red)
                    
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
                        }
                        .controlSize(.small)
                    }
                    
                    Button {
                        print("loggin")
                        loginUser()
                    } label: {
                        Text("Login")
                            .modifier(ButtonModifier())
                    }
                    
                    Text("or")
                    
                    NavigationLink{
                        CreateAccountView(userSelectedInterests: self.$userSelectedInterests)
                    } label: {
                        Text("Create account")
                            .modifier(ButtonModifier())
                    }
                    
                    Text("or")
                    
                    GoogleSignInButton(
                        viewModel: GoogleSignInButtonViewModel(
                            scheme: .dark,
                            style: .wide,
                            state: .normal))
                    {
                        Task {
                            do {
                                try await googleSignIn()
                            } catch {
                                print(error)
                            }
                        }
                    }
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(
                        Capsule().fill(Color(red: 83/255, green: 131/255, blue: 236/255))
                            .frame(height: 50)
                    )
                    Spacer()
                    
                }
                .padding(.top, 50)
                .frame(width: 300)
                .onAppear {
                    Auth.auth().addStateDidChangeListener {
                        auth, user in
                        if user != nil {
                            Task {
                                do {
                                    try await getUserInterestSelection()
                                } catch {
                                    print(error)
                                }
                            }
                            authViewModel.logIn()
                            
                        }
                        
                    }
                }
            }
            .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity)
            .background(backgroundColor)
        }
    }
    
    private func loginUser() {
        Auth.auth().signIn(withEmail: authViewModel.username, password: authViewModel.password) {
            (authResult,error) in
                if let error = error as NSError? {
                    errorMessage = "\(error.localizedDescription)"
                } else {
                    errorMessage = ""
                }
        }
    }
    
    private func getUserInterestSelection() async throws {
        let user = Auth.auth().currentUser
        if let user = user {
            let email = user.email!
            
            await Firestore.firestore().collection("users").getDocuments { snapshot, error in
                
                if let error = error {
                    errorMessage = "\(error)"
                    return
                }
                
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let docEmail = document["email"] as? String,
                           docEmail.caseInsensitiveCompare(email) == .orderedSame {
                            userInterests = document["interests"] as! [String]
                            if userInterests.count == 0 {
                                userSelectedInterests = false
                            }
                            break
                        }
                    }
                }
            }
            
        } else {
            print("this shouldn't happen")
        }
    }
    
    private func googleSignIn() async throws {
        guard let topVC = await UIApplication.getTopViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidSignInResult.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signIn(with: credential) {
            result, error in
            if let error = error {
                print(error)
            }
            
            let user = result?.user
            let email = user?.email
            
            let userData = ["email": email!, "interests": []] as [String : Any]
            
            Firestore.firestore().collection("users").document(email!).setData(userData) {
                error in
                if let error = error {
                    errorMessage = "\(error)"
                } else {
                    errorMessage = ""
                }
            }
        }
        
    }
}

#Preview {
    LoginView()
}
