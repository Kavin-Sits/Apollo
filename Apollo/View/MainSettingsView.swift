//
//  MainSettingsView.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 10/15/23.
//

import SwiftUI

struct MainSettingsView: View {
    @State private var isNightModeOn = false
    @State private var isSoundEffectsOn = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    NavigationLink(destination: Text("Change Password")) {
                        Text("Change Password")
                    }
                    NavigationLink(destination: Text("Update Preferences")) {
                        Text("Update Preferences")
                    }
                    NavigationLink(destination: Text("Update Location")) {
                        Text("Update Location")
                    }
                    NavigationLink(destination: Text("Update Occupation")) {
                        Text("Update Occupation")
                    }
                    NavigationLink(destination: Text("Update Profile Photo")) {
                        Text("Update Profile Photo")
                    }
                    NavigationLink(destination: Text("Update Notification Preferences")) {
                        Text("Update Notification Preferences")
                    }
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
        .background(Color.blue)
    }
}

#Preview {
    MainSettingsView()
}
