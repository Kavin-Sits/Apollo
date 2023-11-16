//
//  PasswordChangeView.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 11/5/23.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct PasswordChangeView: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var isModalPresented: Bool
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        VStack {
            SecureField("Current Password", text: $currentPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("New Password", text: $newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if let user = Auth.auth().currentUser {
                    let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
                        user.reauthenticate(with: credential) { (result, error) in
                        if let error = error {
                            print("CURRENT USER: \(Auth.auth().currentUser?.email ?? "NONE")")
                            print("\(error.localizedDescription)")
                        } else {
                            print("success CURRENT USER: \(Auth.auth().currentUser?.email ?? "NONE")")
                            Auth.auth().currentUser?.updatePassword(to: newPassword)
                        }
                    }
                }
                isModalPresented = false
            }) {
                Text("Change Password")
            }
        }
        .padding()
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
    }
}
