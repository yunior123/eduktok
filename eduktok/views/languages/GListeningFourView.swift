//
//  GListeningFourView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 30/3/24.
//
import FirebaseFirestore
import SwiftUI
import PhotosUI

struct GListeningFourView: View {
    let model: GListeningFourModel
    let onFinished: () -> Void
    let languageCode: String
    let audioUrlDict: [String: [String:String]]
    let userModel: UserModel
    @StateObject private var viewModel = GListeningViewModel()
    
    var body: some View {
        VStack(alignment:.center) {
            HStack (alignment:.center){
                Text(viewModel.titleModel?.textDict[languageCode] ?? "")
                    .font(.title2) // Larger font size
                    .fontWeight(.bold) // Adds boldness
                Button(action: {
                    viewModel.playAudio()
                }) {
                    Image(systemName: "play.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(20)
            .background(Color(.lightGray)) // Light background for the title
            .cornerRadius(8) // Rounded corners for the title container
            ForeFourView(
                models: viewModel.foreModels,
                viewModel: viewModel,
                userModel: userModel,
                unitNumber: model.unitNumber,
                lessonId: model.id
            )
        }
        .onAppear(){
            viewModel.foreModels = model.foreModels
            viewModel.titleModel = model.foreModels.first // Initialize titleModel
            viewModel.onFinished = onFinished
            viewModel.languageCode = languageCode
            viewModel.audioUrlDict = audioUrlDict
            viewModel.preloadPlayInitialAudio() // Preload audio for the first title
            viewModel.setupAudioPlayers()
        }
    }
}

struct ForeFourView: View {
    let models: [ListeningModel]
    @ObservedObject var viewModel: GListeningViewModel
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedModelId: String?
    let userModel: UserModel
    let unitNumber: Int
    let lessonId: String
    
    let gridLayout = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout, spacing: 10) {
                ForEach(models) { model in
                    ZStack(alignment: .topTrailing) {
                        ForeCardView(model: model, viewModel: viewModel)
                            .frame(width: 200, height: 200)
                            .onTapGesture {
                                viewModel.checkMatch(selectedModel: model)
                            }
                        
                        if userModel.role == "admin" {
                            Button(action: {
                                selectedModelId = model.id
                                showImagePicker = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.blue)
                                    .padding(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        
        
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { oldImage, newImage in
            print("Selected Image Changed")
            if let image = newImage,
               let modelId = selectedModelId {
                handleImageSelection(image: image, modelId: modelId, lessonId: lessonId)
            }
        }
        
    }
    func updateModelImage(modelId: String, newImageUrl: URL, lessonId: String) async {
        // Update foreModels
        if let index = viewModel.foreModels.firstIndex(where: { $0.id == modelId }) {
            viewModel.foreModels[index].imageUrl = newImageUrl
            // Update in Firestore
            do {
                try await updateModelInFirestore(
                    modelId: modelId,
                    imageUrl: newImageUrl,
                    lessonId: lessonId
                )
            } catch {
                print("Error updating model in Firestore: \(error)")
            }
        }
    }
    
    private func updateModelInFirestore(modelId: String, imageUrl: URL,lessonId: String) async throws {
        let db = Db().firestore
        let lessonRef = db.collection("lessonsNew").document(lessonId)
        
        // First, get the current document
        let documentSnapshot = try await lessonRef.getDocument()
        
        guard let data = documentSnapshot.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve document data"])
        }
        
        // Get both model arrays
        guard var foreModels = data["foreModels"] as? [[String: Any]]else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve models"])
        }
        
        var updatedForeModels = false
        
        // Check and update foreModels
        if let index = foreModels.firstIndex(where: { ($0["id"] as? String) == modelId }) {
            var updatedModel = foreModels[index]
            updatedModel["imageUrl"] = imageUrl.absoluteString
            foreModels[index] = updatedModel
            updatedForeModels = true
        }
        
        // Update the document with the modified arrays
        var updateData: [String: Any] = [:]
        
        if updatedForeModels {
            updateData["foreModels"] = foreModels
        }
        
        if !updateData.isEmpty {
            try await lessonRef.updateData(updateData)
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model ID not found in either foreModels or backModels"])
        }
    }
    
    private func handleImageSelection(image: UIImage, modelId: String, lessonId: String) {
        Task {
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                    print("Failed to convert image to data")
                    return
                }
                
                let path = createImageFilePath(
                    unitNumber: unitNumber,
                    id: lessonId+modelId
                )
                
                let imageUrl = try await uploadImageToFirebaseC(
                    image: imageData,
                    path: path
                )
                
                await updateModelImage(
                    modelId: modelId,
                    newImageUrl: imageUrl,
                    lessonId: lessonId
                )
            } catch {
                print("Error uploading image: \(error)")
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // Only allow images
        config.selectionLimit = 1 // Limit selection to one image
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No need to update the picker
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first, result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
                parent.dismiss()
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = uiImage
                    }
                }
                DispatchQueue.main.async {
                    self.parent.dismiss()
                }
            }
        }
    }
}

func createImageFilePath(unitNumber: Int, id: String) -> String {
    return "images_new_lessons/unit_\(unitNumber)_id_\(id).jpg"
}

