//
//  InterestSelectionView.swift
//  Apollo
//
//  Created by Srihari Manoj on 10/16/23.
//

import SwiftUI

struct InterestSelectionView: View {
    @State private var selectedOptions: Set<String> = []

    let optionNames = [
        "Sports", "Business", "Technology", "Art and Culture",
        "Literature", "Government and Politics", "Health and Medicine",
        "Entertainment", "International Affairs"
    ]

    var body: some View {
        ZStack {
            Color(red: 0.58135551552097409, green: 0.67444031521406167, blue: 1)
                .ignoresSafeArea()

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

                Spacer()
            }
        }
    }

    func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }
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
    InterestSelectionView()
}
