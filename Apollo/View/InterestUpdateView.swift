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
    @State private var errorMessage: String = ""
    @State private var updateOptions: Bool = false
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
                if selectedOptions.count == 0 {
                    errorMessage = "Please select at least one option"
                } else {
                    storeInterestSelections()
                    errorMessage = ""
                    updateOptions = true
                    presentationMode.wrappedValue.dismiss()
                }
            }
            Text(errorMessage)
                .foregroundStyle(.red)

            Spacer()
        }
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
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
    
    private func storeInterestSelections() {
        AppSession.saveInterests(Array(selectedOptions), for: userEmail)
    }
    
    private func loadUserPreferences() {
            Task {
                let interests = await AppSession.loadInterests()
                await MainActor.run {
                    selectedOptions = Set(interests)
                }
            }
        }
}

#Preview {
    InterestSelectionView(email: "test2@gmail.com")
}
