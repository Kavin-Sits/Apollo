//
//  InterestUpdateView.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 11/15/23.
//


import SwiftUI

struct InterestUpdateView: View {
    var userEmail: String
    @State private var selectedOptions: Set<String> = []
    @State private var updateOptions: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    @EnvironmentObject var nightModeManager: NightModeManager
    @Environment(\.presentationMode) var presentationMode

    init(email: String) {
        userEmail = email
    }
    
    let optionNames = [
        "Sports", "Business", "Technology", "Art and Culture",
        "Literature", "Government and Politics", "Health and Medicine",
        "Entertainment", "International Affairs"
    ]

//    var body: some View {
//        NavigationStack {
//            content.navigationDestination(isPresented: $updateOptions) {
//                MainSettingsView().navigationBarBackButtonHidden(true)
//            }
//        }
//    }
    
    var body: some View {

        VStack(spacing: 20) {

            Text("Update your topic preferences here.")
                .font(.system(size: 20))
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(optionNames, id: \.self) { option in
                        RadioButton(
                            text: option,
                            isSelected: selectedOptions.contains(option),
                            onTap: {
                                toggleOption(option)
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
//                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            Button("Continue") {
                if selectedOptions.isEmpty {
                    presentAlert("Please select at least one option.")
                } else {
                    Task {
                        do {
                            try await storeInterestSelections()
                            await MainActor.run {
                                updateOptions = true
                                presentationMode.wrappedValue.dismiss()
                            }
                        } catch {
                            await MainActor.run {
                                presentAlert(error.localizedDescription)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
        .alert("Unable to Update Interests", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
//            nightModeManager.isNightMode = UserDefaults.standard.bool(forKey: "nightModeEnabled")
            loadUserPreferences()
        }
    }

    func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }
    }
    
    private func storeInterestSelections() async throws {
        try await AppSession.saveInterests(Array(selectedOptions), for: userEmail)
    }
    
    private func loadUserPreferences() {
            Task {
                let interests = await AppSession.loadInterests()
                await MainActor.run {
                    selectedOptions = Set(interests)
                }
            }
    }

    private func presentAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    InterestSelectionView(email: "test2@gmail.com")
}
