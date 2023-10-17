//
//  LoginView.swift
//  Apollo
//
//  Created by Andy Hsu on 10/13/23.
//

import SwiftUI

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

struct LoginView: View {
    
    @State private var username = ""
    @State private var password = ""
    
    let backgroundColor = Color(red: 148/255, green: 172/255, blue: 255/255)
    
    
    var body: some View {
        NavigationStack{
            backgroundColor.overlay(
                VStack(alignment: .center, spacing: 25) {
                    Text("APOLLO")
                        .font(Font.custom("Bodoni 72 Smallcaps", size: 52))
                    
                    VStack(alignment: .leading) {
                        Text("Username/Email")
                        TextField("username", text: $username)
                            .textFieldStyle(.roundedBorder)
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
                    
                    NavigationLink{
                        InterestSelectionView()
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
            
        }
    }
}

#Preview {
    LoginView()
}
