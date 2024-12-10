//
//  AddTemplateView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 19/2/24.
//

import SwiftUI

struct AddTemplateView: View {
    @ObservedObject private var viewModel: AddTemplateViewModel
    private let userModel: UserModel
    @State var isLoading: Bool = false
    @State private var isShowingSuccess: Bool = false // New state for success message
     
    
    init(userModel: UserModel) {
        self.userModel = userModel
        _viewModel = ObservedObject(wrappedValue: AddTemplateViewModel(userModel: userModel))
    }
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section() {
                    TextField("Title", text: $viewModel.title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(nil)  // Allow multiline
                    
                    TextField("Tags (Separate with spaces or commas)", text: $viewModel.tags)
                    
                    TextField("URL", text: $viewModel.url)
                        .keyboardType(.URL)
                    
                }
                Section(header: Text("Image")) {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .overlay(alignment: .topTrailing) { // Add overlay for delete button
                                Button(action: {
                                    viewModel.deleteImage()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                }
                            }
                    }
                    Button("Select Image") {
                        viewModel.selectImage()
                    }
                }
                
                Section {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task{
                                isLoading = true // Set isLoading to true when adding
                                if await viewModel.validateAndAddTemplate() {
                                    isLoading = false // Set isLoading back to false when done
                                    isShowingSuccess = true
                                    self.endEditing()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canAddTemplate)  // Disable if validation fails
                    }
                    
                    Button("Cancel") {
                        self.endEditing()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle("Add Memory Card") // Set the title of the view
            .alert("Success", isPresented: $isShowingSuccess) { // Alert for success message
                            // Success message
                            Text("Template added successfully!")
                        } message: {
                            EmptyView() // Empty message for success alert
                        }
            .alert("Error", isPresented: $viewModel.isShowingError) {
                // Error presentation in an alert (customize error message here)
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

class ImagePicker: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    static let shared = ImagePicker()
    private var completionHandler: (UIImage?) -> Void = { _ in }
    
    func show(completion: @escaping (UIImage?) -> Void) {
        completionHandler = completion
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = windowScene.windows.first?.rootViewController {
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self
                imagePickerController.sourceType = .photoLibrary
                rootViewController.present(imagePickerController, animated: true, completion: nil)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            completionHandler(nil)
            return
        }
        completionHandler(image)
        picker.dismiss(animated: true, completion: nil)
    }
}
