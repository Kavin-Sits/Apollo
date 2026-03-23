//
//  ProfilePhotoView.swift
//  Apollo
//
//  Created by Srihari Manoj on 11/7/23.
//

import SwiftUI
import Combine

struct ProfilePhotoView: View {
    var userEmail: String
    @State private var showImagePicker = false
    @State private var image: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var cancellable: AnyCancellable? = nil
    @State private var newImagePicked = false
    @EnvironmentObject var nightModeManager: NightModeManager

    init(email: String) {
        userEmail = email
    }

    var body: some View {
        VStack {
            VStack {
                Spacer()
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width / 1.4, height: UIScreen.main.bounds.width / 1.4)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 20)
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width / 1.4, height: UIScreen.main.bounds.width / 1.4)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 20)
                }
                
                Spacer() 

                Button("Choose Profile Photo") {
                    self.showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(Color.white)
                .clipShape(Capsule())

                Spacer()
            }
            .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
            .frame(width: 400)
            .onAppear {
                self.loadProfilePhoto()
            }
            .sheet(isPresented: $showImagePicker, onDismiss: uploadImage) {
                ImagePicker(image: self.$image, newImagePicked: self.$newImagePicked)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Theme.appColors)
        .environment(\.colorScheme, nightModeManager.isNightMode ? .dark : .light)
    }

    func loadProfilePhoto() {
        if let image = AppSession.loadProfilePhoto() {
            self.image = image
        }
    }

    func uploadImage() {
        if newImagePicked, let image {
            AppSession.saveProfilePhoto(image)
            newImagePicked = false
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var newImagePicked: Bool
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.newImagePicked = true
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ProfilePhotoView(email: "test2@gmail.com")
}
