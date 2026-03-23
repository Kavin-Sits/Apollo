//
//  CreateAccountView.swift
//  Apollo
//
//  Created by Andy Hsu on 10/14/23.
//

import SwiftUI
import CoreLocationUI

let occupationsList = ["accountant", "actor/actress", "artist", "astronaut", "astronomer", "athelete", "banker", "barber", "biologist", "blacksmith", "butler", "cardiologist", "carpenter", "cashier", "chef", "chemist", "contractor", "dentist", "dermatologist", "designer", "doctor", "ecologist", "economist", "engineer", "entrepreneur", "geologist", "geographer", "hairdresser", "intern", "judge", "journalist", "landscaper", "lawyer", "manager", "marketer", "mechanic", "model", "nurse", "optometrist", "paralegal", "pediatrician", "photographer", "physician", "politician", "producer", "professor", "psychologist", "retailer", "salesperson", "scientist", "sheriff", "student", "statistician", "surgeon", "teacher", "technician", "trader", "usher", "veterinarian", "watier/waitress", "writer"]

struct CreateAccountView: View {
    
    @State private var fullName = ""
    @State private var password = ""
    @State private var email = ""
    @State private var dateOfBirth = ""
    @State private var occupation = ""
    @State private var location = ""
    @State private var selectedOptions: Set<String> = []
    @Binding var userSelectedInterests: Bool
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            
            
            VStack(alignment: .leading) {
                Spacer()
                
                Text("Full Name")
                TextField("", text: $fullName)
                    .textFieldStyle(.roundedBorder)

                Text("Email")
                    .padding(.top, 25)
                TextField("", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                
                Text("Password")
                    .padding(.top, 25)
                SecureField("", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Spacer()
                
            }
            .frame(width: 320)
            .ignoresSafeArea(.keyboard)
            
            
            VStack {
                Spacer()
                
                NavigationLink("Next") {
                    DobLocationOccupationView(fullName: $fullName, password: $password, email: $email, selectedOptions: $selectedOptions, userSelectedInterests: $userSelectedInterests)
                }
                .modifier(ButtonModifier())
                
                Spacer()
            }
            .frame(width: 320)
            .ignoresSafeArea(.keyboard)
            
        }
        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.bottom, 70)
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
    }
    
//    var content: some View {
//
//
//    }
    
}

struct DobLocationOccupationView: View {
    
    @Binding var fullName: String
    @Binding var password: String
    @Binding var email: String
    
    @State private var dateOfBirth = ""
    @State private var occupation = ""
    @State private var location = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @Binding var selectedOptions: Set<String>
    @Binding var userSelectedInterests: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var nightModeManager: NightModeManager
    @Environment(\.dismiss) private var dismiss
    let haptics = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            
            
            VStack(alignment: .leading) {
                Spacer()
                
                Text("Date of Birth")
                    .padding(.top, 25)
                TextField("mm/dd/yyyy", text: $dateOfBirth)
                    .textFieldStyle(.roundedBorder)
                
                Text("Location")
                    .padding(.top, 25)
                
                TextField("", text: $location)
                    .textFieldStyle(.roundedBorder)
                
                Text("Occupation")
                    .padding(.top, 25)
                
                TextField("", text: $occupation)
                    .textFieldStyle(.roundedBorder)
                
                Spacer()
                
            }
            .frame(width: 320)
            .ignoresSafeArea(.keyboard)
            
            
            VStack {
                Spacer()
                
                Button("Create Account") {
                    if fullName != "" && email != "" && password != "" && dateOfBirth != "" && location != "" && occupation != "" {
                        Task {
                            do {
                                try await createUser()
                                await MainActor.run {
                                    authViewModel.logIn()
                                    userSelectedInterests = false
                                    dismiss()
                                }
                            } catch {
                                presentAlert(error.localizedDescription)
                            }
                        }
                    } else {
                        presentAlert("Please go back and ensure that all fields are filled.")
                        self.haptics.notificationOccurred(.warning)
                    }
                    
                }
                .modifier(ButtonModifier())
                
                Spacer()
            }
            .frame(width: 320)
            .ignoresSafeArea(.keyboard)
            
        }
        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.bottom, 70)
        .alert("Unable to Create Account", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
    }
    
    private func createUser() async throws {
        try await AppSession.signUp(
            email: email,
            password: password,
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            location: location,
            occupation: occupation,
            interests: Array(selectedOptions)
        )
    }

    private func presentAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

//#Preview {
//    CreateAccountView()
//}
