//
//  ProfilePhotoView.swift
//  Apollo
//
//  Created by Srihari Manoj on 11/7/23.
//

import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import Combine

struct ProfilePhotoView: View {
    var userEmail: String
    @State private var showImagePicker = false
    @State private var image: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var cancellable: AnyCancellable? = nil
    @State private var newImagePicked = false

    init(email: String) {
        userEmail = email
    }

    var body: some View {
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
                Circle()
                    .fill(Color.gray)
                    .frame(width: UIScreen.main.bounds.width / 1.4, height: UIScreen.main.bounds.width / 1.4)
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
        .frame(width: 400)
        .background(Color(red: 0.58135551552097409, green: 0.67444031521406167, blue: 1))
        .onAppear {
            self.loadProfilePhoto()
        }
        .sheet(isPresented: $showImagePicker, onDismiss: uploadImage) {
            ImagePicker(image: self.$image, newImagePicked: self.$newImagePicked)
        }
    }

    func loadProfilePhoto() {
        Firestore.firestore().collection("users").document(userEmail).getDocument { (document, error) in
            if let document = document, document.exists {
                if let urlString = document.data()?["profilePhotoURL"] as? String, let url = URL(string: urlString) {
                    self.cancellable = URLSession.shared.dataTaskPublisher(for: url)
                        .map { UIImage(data: $0.data) }
                        .replaceError(with: nil)
                        .receive(on: DispatchQueue.main)
                        .sink { downloadedImage in
                            self.image = downloadedImage
                        }
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func uploadImage() {
        if newImagePicked {
            guard let imageData = image?.jpegData(compressionQuality: 0.8) else { return }
            
            let storageRef = Storage.storage().reference(withPath: "profilePhotos/\(UUID().uuidString).jpg")
            let uploadMetadata = StorageMetadata()
            uploadMetadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: uploadMetadata) { (downloadMetadata, error) in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }
                
                storageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        print("Error getting the download URL")
                        return
                    }
                    
                    self.imageURL = downloadURL.absoluteString
                    Firestore.firestore().collection("users").document(self.userEmail).setData(["profilePhotoURL": self.imageURL], merge: true) { error in
                        if let error = error {
                            print("Error writing document: \(error)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                }
            }
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
