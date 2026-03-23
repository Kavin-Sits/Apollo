//
//  MainSettingsView.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 10/15/23.
//

import SwiftUI
import FirebaseAuth
import UIKit

enum Theme {
    static var appColors: Color {
        Color("AppColors")
    }
}

struct MainSettingsView: View {
    //@State private var isNightModeOn = false
    @State private var isSoundEffectsOn = false
    @State private var notifAlert = false
    @State private var newPassword = ""
    @State private var currentPassword = ""
    @State private var isModalPresented = false
    @State private var performDelete = false
    @State private var selectedOccupationIndex = 0
    @State private var isPickerVisible = false
    @State private var showAlert = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var nightModeManager: NightModeManager
    @ObservedObject private var soundEffectManager = SoundEffectManager()
    
    @Environment(\.dismiss) var presentationMode

    private var isGuestMode: Bool {
        AppSession.isGuestModeEnabled && !AppSession.hasAuthenticatedUser
    }

    var body: some View {
        NavigationView {
            VStack{
                Form {
                    Section(header: Text("Account")) {
                        if !isGuestMode {
                            Button(action: {
                                isModalPresented = true
                            }) {
                                Text("Update Password")
                            }
                        }

                        NavigationLink(destination: InterestUpdateView(email: AppSession.currentUserID ?? AppSession.guestUserID)) {
                            Text("Update Preferences")
                        }
                        if !isGuestMode {
                            NavigationLink(destination: UpdateLocationView()) {
                                Text("Update Location")
                            }
                            Button(action: {
                                isPickerVisible.toggle()
                            }) {
                                Text("Update Occupation")
                            }
                            if isPickerVisible {
                                Picker("Select Occupation", selection: $selectedOccupationIndex) {
                                    ForEach(0..<occupationsList.count, id: \.self) { index in
                                        Text(occupationsList[index]).tag(index)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .padding()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        isPickerVisible.toggle()
                                    }) {
                                        Text("OK")
                                            .padding()
                                    }
                                    Spacer()
                                }
                            }
                            NavigationLink(destination: ProfilePhotoView(email: Auth.auth().currentUser?.email ?? "")) {
                                Text("Update Profile Photo")
                            }
                        }
                    }
                    .sheet(isPresented: $isModalPresented) {
                        PasswordChangeView(
                            currentPassword: $currentPassword,
                            newPassword: $newPassword,
                            isModalPresented: $isModalPresented
                        )
                    }
                    
                    Section(header: Text("Display")) {
                        Toggle(isOn: $nightModeManager.isNightMode) {
                            Text("Night Mode")
                        }
                    }
                    
                    Section(header: Text("Sound")) {
                        Toggle(isOn: $soundEffectManager.soundEnabled) {
                            Text("Sound Effects")
                        }
                        .onReceive(soundEffectManager.$soundEnabled) { newValue in
                            print("soundEnabled changed to \(newValue)")
                        }
                    }
                    
                    Section {
                        NavigationLink(destination: SavedArticlesView()
                            .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)) {
                            Text("View Saved Articles")
                        }

                        Button(action: {
                            do {
                                if AppSession.hasAuthenticatedUser {
                                    try Auth.auth().signOut()
                                }
                                AppSession.endGuestSession()
                                self.presentationMode.callAsFunction()
                                self.authViewModel.logOut()
                                
                            } catch let signOutError as NSError {
                                print("Error signing out: \(signOutError)")
                            }
                            
                        }, label:{
                            Text(isGuestMode ? "Exit Guest Mode" : "Sign Out")
                                .foregroundColor(.blue)
                            
                        })

                        if !isGuestMode {
                            Button(action: {
                                showAlert = true
                            }) {
                                Text("Delete Account")
                                    .foregroundColor(.red)
                            }
                            .alert(isPresented: $showAlert) {
                                Alert(
                                    title: Text("Are you sure?"),
                                    message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        Auth.auth().currentUser?.delete()
                                        do {
                                            try Auth.auth().signOut()
                                            AppSession.endGuestSession()
                                            self.presentationMode.callAsFunction()
                                            self.authViewModel.logOut()
                                        } catch let signOutError as NSError {
                                            print("Error signing out: \(signOutError)")
                                        }
                                        performDelete = true
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                            .navigationDestination(isPresented: $performDelete){
                                LoginView()
                            }
                        }
                    }
                    Button(action: {
                        self.presentationMode.callAsFunction()
                    }, label: {
                        Text("Return".uppercased())
                            .frame(maxWidth: .infinity)
                            .padding()
                    })
                    .font(.headline)
                    .frame(width:300, height: 40)
                    .padding()
                }
                
                .scrollContentBackground(.hidden)
                
                .navigationBarTitle("Settings")
            }
            .background(Theme.appColors)
            .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        }
    }
}


//#Preview {
//    MainSettingsView(notifsAuth: <#Bool#>)
//}
