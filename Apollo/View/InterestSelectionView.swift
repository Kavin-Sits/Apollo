//
//  InterestSelectionView.swift
//  Apollo
//
//  Created by Srihari Manoj on 10/16/23.
//

import SwiftUI
import FirebaseFirestore

struct InterestSelectionView: View {
    var userEmail: String
    @State private var selectedOptions: Set<String> = []
    @State private var errorMessage: String = ""
    @State private var updateOptions: Bool = false

    init(email: String) {
        userEmail = email
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
            
            Text("Which topics interest you?")
                .font(.title)
                .foregroundColor(.white)

            Text("We'll try to curate your selection based on your preferences.")
                .font(.headline)
                .foregroundColor(.white)
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
                        .background(Color.white)
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
                }
            }
            Text(errorMessage)
                .foregroundStyle(.red)

            Spacer()
        }
        .background(Color(red: 224/255, green: 211/255, blue: 175/255))
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
