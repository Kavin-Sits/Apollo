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

struct LoginView: View {
    
    @State private var username = ""
    @State private var password = ""
    @State private var userLoggedIn = false
    @State private var errorMessage = ""
    @State private var userInterests: [String] = []
    
    let backgroundColor = Color(red: 148/255, green: 172/255, blue: 255/255)
    
    var body: some View {
        if userLoggedIn {
            if userInterests.count == 0 {
                InterestSelectionView(email: (Auth.auth().currentUser?.email)!)
            } else {
                TestView()
            }
            
        } else {
            content
        }
    }
    
    var content: some View {
        NavigationStack{
            backgroundColor.overlay(
                VStack(alignment: .center, spacing: 25) {
                    Text("APOLLO")
                        .font(Font.custom("Bodoni 72 Smallcaps", size: 52))
                    Text(errorMessage)
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading) {
                        Text("Username/Email")
                        TextField("username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .padding(.top, 10)
                        Text("Password")
                            .padding(.top, 10)
                        SecureField("password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.top, 10)
                        Button("Forgot password") {
                            print("forgot password")
                        }
                        .controlSize(.small)
                    }
                    .padding(.top, 40)
                    
                    Button {
                        print("loggin")
                        loginUser()
                    } label: {
                        Text("Login")
                        .frame(width: 150, height: 50)
                        .background(Color(red: 1, green: 1, blue: 1))
                        .clipShape(Capsule())
                        .padding(.top, 50.0)
                    }
                    
                    Text("or")
                    
                    NavigationLink{
                        CreateAccountView()
                    } label: {
                        Text("Create account")
                        .frame(width: 150, height: 50)
                        .background(Color(red: 1, green: 1, blue: 1))
                        .clipShape(Capsule())
                    }
                
                    
                    // replace this with Google sign on button
                    Button("Sign in with Google") {
                        print("Google sign on")
                    }
                    .frame(width: 150, height: 50)
                    .background(Color(red: 1, green: 1, blue: 1))
                    .clipShape(Capsule())
                    
                    
                    Spacer()
                    
                }
                    .padding(.top, 175.0)
                    .frame(width: 300)
                
            )
            .ignoresSafeArea()
            .onAppear {
//                do {
//                    try Auth.auth().signOut()
//                } catch {
//                    print("Sign out error")
//                }
                Auth.auth().addStateDidChangeListener {
                    auth, user in
                    if user != nil {
                        userLoggedIn.toggle()
                        getUserInterestSelection()
                    }
                    
                }
            }
        }
        
    }
    private func loginUser() {
        Auth.auth().signIn(withEmail: username, password: password) {
            (authResult,error) in
                if let error = error as NSError? {
                    errorMessage = "\(error.localizedDescription)"
                } else {
                    errorMessage = ""
                }
        }
    }
    
    private func getUserInterestSelection(){
        let user = Auth.auth().currentUser
        if let user = user {
            let email = user.email!
            
            Firestore.firestore().collection("users").getDocuments { snapshot, error in
                
                if let error = error {
                    errorMessage = "\(error)"
                    return
                }
                
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let docEmail = document["email"] as? String,
                           docEmail.caseInsensitiveCompare(email) == .orderedSame {
                            userInterests = document["interests"] as! [String]
                            print("found user interests")
                            print(userInterests)
                            break
                        }
                    }
                }
            }
        } else {
            print("this shouldn't happen")
        }
    }
}

#Preview {
    LoginView()
}
