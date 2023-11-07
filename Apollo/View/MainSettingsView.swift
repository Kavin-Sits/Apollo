//
//  MainSettingsView.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 10/15/23.
//

import SwiftUI
import FirebaseAuth
import UIKit

struct MainSettingsView: View {
    @State private var isNightModeOn = false
    @State private var isSoundEffectsOn = false
    @State private var notifAlert = false
    @State private var newPassword = ""
    @State private var currentPassword = ""
    @State private var isModalPresented = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    Button(action: {
                        isModalPresented = true
                    }) {
                        Text("Update Password")
                    }

                    NavigationLink(destination: InterestSelectionView(email: Auth.auth().currentUser?.email ?? "")) {
                        Text("Update Preferences")
                    }
                    NavigationLink(destination: UpdateLocationView()) {
                        Text("Update Location")
                    }
                    NavigationLink(destination: Text("Update Occupation")) {
                        Text("Update Occupation")
                    }
                    NavigationLink(destination: Text("Update Profile Photo")) {
                        Text("Update Profile Photo")
                    }
//                    Button(action: {
//                        notifAlert = true
//                    }) {
//                        Text("Update Notification Preferences")
//                    }
                }
                .sheet(isPresented: $isModalPresented) {
                    PasswordChangeView(
                        currentPassword: $currentPassword,
                        newPassword: $newPassword,
                        isModalPresented: $isModalPresented
                    )
                }
//                .alert(isPresented: $notifAlert) {
//                    Alert(
//                        title: Text("Notification Preferences"),
//                            message: Text(notifAuthorization ? "Your notifications are currently enabled. Would you like to disable them?" : "Your notifications are currently disabled. Would you like to enable them?"),
//                            primaryButton: .default(Text(notifAuthorization ? "Disable" : "Enable")) {
//                                if(notifAuthorization){
//                                    UIApplication.shared.unregisterForRemoteNotifications()
//                                    print("disabled")
//                                    notifAuthorization = false
//                                    notifAlert = false
//                                } else {
//                                    //notifAlert = false
//                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) {
//                                        (granted,error) in
//                                        if granted {
//                                            notifAuthorization = true
//                                            print("enabled")
//                                        }
//                                        else if let error = error {
//                                            print(error.localizedDescription)
//                                        }
//                                    }
//                                }
//                            },
//                            secondaryButton: .cancel()
//                        )
//                    }
//                .alert(isPresented: $passwordChangeAlert) {
//                    Alert(
//                        // need to add text fields for current and new password to alert
//                        title: Text("Update Password"),
//                        message: Text("To update your password, please input your current password and new password."),
//                        primaryButton: .default(Text("Change")) {
//                            if let user = Auth.auth().currentUser {
//                                let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
//                                user.reauthenticate(with: credential) { (result, error) in
//                                    if let error = error {
//                                        print("\(error.localizedDescription)")
//                                    } else {
//                                        print("success")
//                                        Auth.auth().currentUser?.updatePassword(to: newPassword)
//                                    }
//                                }
//                            }
//                        },
//                        secondaryButton: .cancel()
//                    )
//                }
                
                Section(header: Text("Display")) {
                    Toggle(isOn: $isNightModeOn) {
                        Text("Night Mode")
                    }
                }
                
                Section(header: Text("Sound")) {
                    Toggle(isOn: $isSoundEffectsOn) {
                        Text("Sound Effects")
                    }
                }
                
                Section {
                    Button(action: {
                    }) {
                        Text("View History")
                    }

                    NavigationLink(destination: LoginView()) {
                        Text("Sign Out")
                            .foregroundColor(.blue)
                    }
                    .background(
                        Button(action: {
                                
                            do {
                                //userLoggedIn = false
                                try Auth.auth().signOut()
                            } catch let signOutError as NSError {
                                print("Error signing out: \(signOutError)")
                            }
                                
                        }) {
                            EmptyView() // Use EmptyView to make the button invisible
                        }
                    )
//                    NavigationLink(destination: LoginView()) {
//                        Text("Sign Out")
//                    }
//                    .simultaneousGesture(TapGesture().onEnded {
//                        do {
//                            userLoggedIn = false
//                            try Auth.auth().signOut()
//                        } catch let signOutError as NSError {
//                            print("Error signing out: \(signOutError)")
//                        }
//                    })
                    Button(action: {
                    }) {
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                }
            }
            .background(Color(red: 0.58135551552097409, green: 0.67444031521406167, blue: 1))
            .scrollContentBackground(.hidden)
            .environment(\.colorScheme, isNightModeOn ? .dark : .light)
            .navigationBarTitle("Settings")
        }
    }
}


//#Preview {
//    MainSettingsView(notifsAuth: <#Bool#>)
//}
