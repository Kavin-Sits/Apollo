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
    @State private var performDelete = false
    @State private var selectedOccupationIndex = 0
    @State private var isPickerVisible = false
    @State private var showAlert = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Environment(\.dismiss) var presentationMode

    var body: some View {
        NavigationView {
            VStack{
                Button(action: {
                    self.presentationMode.callAsFunction()
                }, label: {
                    Text("Return".uppercased())
                })
                .font(.headline)
                .padding()
                .frame(width:300, height: 50)
                .background(Rectangle()
                    .fill(Color.white)
                ).padding(.top, 10)
                
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
                        //TODO change user data
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
                    .sheet(isPresented: $isModalPresented) {
                        PasswordChangeView(
                            currentPassword: $currentPassword,
                            newPassword: $newPassword,
                            isModalPresented: $isModalPresented
                        )
                    }
                    
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
                        
                        @EnvironmentObject var authViewModel: AuthViewModel
                        
                        Button(action: {
                            do {
                                try Auth.auth().signOut()
                                self.presentationMode.callAsFunction()
                                self.authViewModel.logOut()
                                
                            } catch let signOutError as NSError {
                                print("Error signing out: \(signOutError)")
                            }
                            
                        }, label:{
                            Text("Sign Out")
                                .foregroundColor(.blue)
                            
                        })
                        
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
                .background(Color(red: 0.58135551552097409, green: 0.67444031521406167, blue: 1))
                .scrollContentBackground(.hidden)
                .environment(\.colorScheme, isNightModeOn ? .dark : .light)
                .navigationBarTitle("Settings")
            }
            .background(Color(red: 0.58135551552097409, green: 0.67444031521406167, blue: 1))
        }
    }
}


//#Preview {
//    MainSettingsView(notifsAuth: <#Bool#>)
//}
