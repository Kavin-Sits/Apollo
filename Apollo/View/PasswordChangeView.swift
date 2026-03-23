//
//  PasswordChangeView.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 11/5/23.
//

import Foundation
import SwiftUI

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
                Task {
                    do {
                        try await AppSession.updatePassword(newPassword)
                    } catch {
                        print(error.localizedDescription)
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
