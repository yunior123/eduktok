//
//  GSpeakingView 2.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 30/12/24.
//


struct GSpeakingView: View {
    let model: GSpeakingModel
    let onFinished: () -> Void
    let languageCode: String
    let audioUrlDict: [String: [String:String]]
    let userModel: UserModel
    @StateObject private var viewModel = GSpeakingViewModel()
    @State private var activeCardIndex: Int = 0
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedModelId: String?
    
    let gridLayout = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: gridLayout, spacing: 10) {
                    ForEach(viewModel.models.indices, id: \.self) { index in
                        let language = Locale(identifier: languageCode)
                        ZStack(alignment: .topTrailing) {
                            SCardView(
                                model: viewModel.models[index],
                                language: language,
                                index: index,
                                activeCardIndex: $activeCardIndex,
                                viewModel: viewModel
                            )
                            
                            if userModel.role == "admin" {
                                Button(action: {
                                    selectedModelId = viewModel.models[index].id
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
            .padding([.top, .leading, .trailing])
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage,
                           let modelId = selectedModelId {
                            handleImageSelection(image: image, modelId: modelId)
                        }
                    }
            }
        }
        .onAppear {
            viewModel.models = model.models
            viewModel.onFinished = onFinished
            viewModel.languageCode = languageCode
            viewModel.audioUrlDict = audioUrlDict
            activeCardIndex = 0
            setupAudioSession()
        }
    }
    
    private func setupAudioSession() {
        DispatchQueue.global(qos: .background).async {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("❌ Failed to set up play and record sessions")
                print("❌ \(error.localizedDescription)")
            }
        }
    }
    
    private func handleImageSelection(image: UIImage, modelId: String) {
        Task {
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                    print("Failed to convert image to data")
                    return
                }
                
                let path = createImageFilePath(
                    unitNumber: model.unitNumber,
                    id: model.id + modelId
                )
                
                let imageUrl = try await uploadImageToFirebaseC(
                    image: imageData,
                    path: path
                )
                
                await updateModelImage(
                    modelId: modelId,
                    newImageUrl: imageUrl,
                    lessonId: model.id
                )
            } catch {
                print("Error uploading image: \(error)")
            }
        }
    }
    
    private func updateModelImage(modelId: String, newImageUrl: URL, lessonId: String) async {
        if let index = viewModel.models.firstIndex(where: { $0.id == modelId }) {
            viewModel.models[index].imageUrl = newImageUrl
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
    
    private func updateModelInFirestore(modelId: String, imageUrl: URL, lessonId: String) async throws {
        let db = Db().firestore
        let lessonRef = db.collection("lessonsNew").document(lessonId)
        
        let documentSnapshot = try await lessonRef.getDocument()
        
        guard let data = documentSnapshot.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve document data"])
        }
        
        guard var models = data["models"] as? [[String: Any]] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve models"])
        }
        
        if let index = models.firstIndex(where: { ($0["id"] as? String) == modelId }) {
            var updatedModel = models[index]
            updatedModel["imageUrl"] = imageUrl.absoluteString
            models[index] = updatedModel
            
            try await lessonRef.updateData([
                "models": models
            ])
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model ID not found in models array"])
        }
    }
}