//
//  ResetPassword.swift
//  Apollo
//
//  Created by Andy Hsu on 11/6/23.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ForgotPasswordView: View {
    
    let backgroundColor = Color(red: 224/255, green: 211/255, blue: 175/255)
    
    @State private var email = ""
    @State private var statusMessage = ""
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        backgroundColor.overlay(
            VStack {
                Text("Reset password")
                
                TextField("email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .padding(.top, 10)
                
                Button {
                    Auth.auth().sendPasswordReset(withEmail: email) {
                        error in
                        if let error = error {
                            print(error)
                        } else {
                            statusMessage = "Sent reset password link to \(email)"
                        }
                    }
                } label: {
                    Text("Send link")
                    .frame(width: 150, height: 50)
                    .background(Color(red: 1, green: 1, blue: 1))
                    .clipShape(Capsule())
                    .padding(.top, 50.0)
                }
                
                Text(statusMessage)
                
            }
            .frame(width: 300)
            .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        )
        .ignoresSafeArea()
        
    }
}

#Preview {
    ForgotPasswordView()
}
