//
//  InterestSelectionView.swift
//  Apollo
//
//  Created by Srihari Manoj on 10/16/23.
//

import SwiftUI
struct InterestSelectionView: View {
    var userEmail: String
    var onComplete: (() -> Void)?
    @State private var selectedOptions: Set<String> = []
    @State private var updateOptions: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    @EnvironmentObject var nightModeManager: NightModeManager
    let haptics = UINotificationFeedbackGenerator()

    init(email: String, onComplete: (() -> Void)? = nil) {
        userEmail = email
        self.onComplete = onComplete
    }
    
    let optionNames = [
        "Sports", "Business", "Technology", "Art and Culture",
        "Literature", "Government and Politics", "Health and Medicine",
        "Entertainment", "International Affairs"
    ]

    var body: some View {
        NavigationStack {
            content.navigationDestination(isPresented: $updateOptions) {
                HomeView().navigationBarBackButtonHidden(true)
            }
        }
    }
    
    var content: some View {

        VStack(spacing: 20) {
            Spacer()
            
            Text("Which topics interest you?")
                .font(.title)

            Text("We'll try to curate your selection based on your preferences.")
                .font(.headline)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 15) {
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
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            Button("Continue") {
                if selectedOptions.isEmpty {
                    presentAlert("Please select at least one option.")
                    self.haptics.notificationOccurred(.warning)
                } else {
                    Task {
                        do {
                            try await storeInterestSelections()
                            await MainActor.run {
                                if let onComplete {
                                    onComplete()
                                } else {
                                    updateOptions = true
                                }
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
        .onAppear() {
            loadUserPreferences()
        }
        .alert("Unable to Save Interests", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
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

struct RadioButton: View {
    var text: String
    var isSelected: Bool
    var onTap: () -> Void
    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundColor(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 25, height: 25)
                .onTapGesture {
                    onTap()
                }
        }
    }
}

#Preview {
    InterestSelectionView(email: "test2@gmail.com")
}
