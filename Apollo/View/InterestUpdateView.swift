//
//  InterestUpdateView.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 11/15/23.
//


import SwiftUI
import FirebaseFirestore

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
                .foregroundColor(.white)
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
        Firestore.firestore().collection("users").document(userEmail).setData(["interests": Array(selectedOptions)], merge: true)
    }
    
    private func loadUserPreferences() {
            Firestore.firestore().collection("users").document(userEmail).getDocument { document, error in
                if let document = document, document.exists {
                    if let data = document.data(), let interests = data["interests"] as? [String] {
                        selectedOptions = Set(interests)
                        print("here")
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }
}

#Preview {
    InterestSelectionView(email: "test2@gmail.com")
}

