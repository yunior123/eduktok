//
//  AvatarView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//

import SwiftUI
import FirebaseStorage

struct AvatarView: View {
    @State private var userImage: UIImage? = nil
    @State private var isEditing = false
    let user: UserModel
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) { // Stack for the edit button overlay
            if let urlString = user.avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            }
            else  if let userImage = userImage  {
                Image(uiImage: userImage )
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(Image(systemName: "person.fill"))
            }
            
            Button(action: { isEditing.toggle() }) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                    .padding(8)
                    .background(.white)
                    .clipShape(Circle())
            }
        }
        .sheet(isPresented: $isEditing) { // Present ImagePicker as a sheet
            ImagePickerView(sourceType: .photoLibrary) { selectedImage in
                userImage = selectedImage
                Task{
                    try await viewModel.uploadProfilePicture(image: selectedImage)
                }
            }
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

