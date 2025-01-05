//
//  LanguagesLearningView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 29/2/24.
//

import SwiftUI
import AVKit

struct ForeCardView: View {
    
    let model: ListeningModel
    @ObservedObject var viewModel : GListeningViewModel
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        VStack {
            if (viewModel.shouldTransition) || (viewModel.isCardMatched ?? false) && (
                model.textDict[viewModel.languageCode!] == viewModel.titleModel?
                    .textDict[viewModel.languageCode!]
            ) {
                HStack {
                    Text(model.textDict[viewModel.languageCode!]!)
                        .font(.headline) // Larger font size
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: {
                        playAudio()
                    }) {
                        Image(systemName: "play.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    
                }
            }
            
            CachedAsyncImage(url: model.imageUrl!, placeholder: Image(systemName: "photo"))
            
        }
        .overlay(alignment: .center) { // Overlay modifier
            if (viewModel.tappedCardId == model.id) {
                if (viewModel.isCardMatched ?? false) && (model.textDict[viewModel.languageCode!]! == viewModel.titleModel?.textDict[viewModel.languageCode!]!) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()   // Add inner padding
        .background(Color.white)  // Set a background color
        .cornerRadius(10)         // Add rounded corners
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1) // Create a border
        )
        .shadow(radius: 3)        // Add a subtle shadow
        .onAppear {
            DispatchQueue.global(qos: .background).async {
                do {
                    let langCode = viewModel.languageCode!
                    let text = model.textDict[langCode]!;
                    let audioDict = viewModel.audioUrlDict!
                    let urlString = audioDict[langCode]![text]!
                    guard let url = URL(string:urlString)  else { return }
                    URLSession.shared.dataTask(with: url) { (data, response, error) in
                        if let error = error {
                            print("Error fetching audio: \(error)")
                            return
                        }
                        
                        guard let data = data else {
                            print("No audio data found")
                            return
                        }
                        
                        player = try? AVAudioPlayer(data: data)
                        player?.prepareToPlay()
                        player?.volume = 1.0
                        
                    }.resume()
                } 
            }
        }
    }
    
    func playAudio() {
        player?.play()
    }
}

struct BackCardView: View {
    let model: ListeningModel
    @ObservedObject var viewModel : GListeningViewModel
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        VStack {
            HStack {
                Text(model.textDict[viewModel.languageCode!]!)
                    .font(.headline) // Larger font size
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    playAudio()
                }) {
                    Image(systemName: "play.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            CachedAsyncImage(url: model.imageUrl!, placeholder: Image(systemName: "photo"))
            
        }
        .padding()   // Add inner padding
        .background(Color.white)  // Set a background color
        .cornerRadius(10)         // Add rounded corners
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1) // Create a border
        )
        .shadow(radius: 3)        // Add a subtle shadow
        .onAppear {
            
            let langCode = viewModel.languageCode!
            let text = model.textDict[langCode]!;
            let audioDict = viewModel.audioUrlDict!
            let urlString = audioDict[langCode]![text]!
            
            guard let url = URL(string:urlString)  else { return }
            
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error fetching audio: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No audio data found")
                    return
                }
                
                player = try? AVAudioPlayer(data: data)
                player?.prepareToPlay()
                player?.volume = 1.0
                
            }.resume()
        }
    }
    
    func playAudio() {
        player?.play()
    }
}

struct BackView: View {
    let models: [ListeningModel]
    @ObservedObject var viewModel: GListeningViewModel
    let userModel: UserModel
    let unitNumber: Int
    let lessonId:String
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedModelId: String?
    
    func updateModelImage(modelId: String, newImageUrl: URL, lessonId: String) async {
        // Check and update foreModels
        if let index = viewModel.foreModels.firstIndex(where: { $0.id == modelId }) {
            viewModel.foreModels[index].imageUrl = newImageUrl
        }
        
        // Check and update backModels
        if let index = viewModel.backModels.firstIndex(where: { $0.id == modelId }) {
            viewModel.backModels[index].imageUrl = newImageUrl
        }
        
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
    
    private func handleImageSelection(image: UIImage,modelId:String, lessonId: String) {
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
    private func updateModelInFirestore(modelId: String, imageUrl: URL,lessonId: String) async throws {
        let db = Db().firestore
        let lessonRef = db.collection("lessonsNew").document(lessonId)
        
        // First, get the current document
        let documentSnapshot = try await lessonRef.getDocument()
        
        guard let data = documentSnapshot.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve document data"])
        }
        
        // Get both model arrays
        guard var foreModels = data["foreModels"] as? [[String: Any]],
              var backModels = data["backModels"] as? [[String: Any]] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve models"])
        }
        
        var updatedForeModels = false
        var updatedBackModels = false
        
        // Check and update foreModels
        if let index = foreModels.firstIndex(where: { ($0["id"] as? String) == modelId }) {
            var updatedModel = foreModels[index]
            updatedModel["imageUrl"] = imageUrl.absoluteString
            foreModels[index] = updatedModel
            updatedForeModels = true
        }
        
        // Check and update backModels
        if let index = backModels.firstIndex(where: { ($0["id"] as? String) == modelId }) {
            var updatedModel = backModels[index]
            updatedModel["imageUrl"] = imageUrl.absoluteString
            backModels[index] = updatedModel
            updatedBackModels = true
        }
        
        // Update the document with the modified arrays
        var updateData: [String: Any] = [:]
        
        if updatedForeModels {
            updateData["foreModels"] = foreModels
        }
        
        if updatedBackModels {
            updateData["backModels"] = backModels
        }
        
        if !updateData.isEmpty {
            try await lessonRef.updateData(updateData)
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model ID not found in either foreModels or backModels"])
        }
    }
    
    var body: some View {
        ScrollView {
            LazyHStack {
                ForEach(models) { model in
                    ZStack(alignment: .topTrailing) {
                        BackCardView(model: model, viewModel: viewModel)
                            .frame(width: 200, height: 200)
                        
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
        .onChange(of: selectedImage) { old, newImage in
            if let image = newImage,
               let modelId = selectedModelId {
                Task {
                   handleImageSelection(image: image, modelId: modelId, lessonId: lessonId)
                }
            }
        }
    }
}

struct ForeView: View {
    let models: [ListeningModel]
    @ObservedObject var viewModel: GListeningViewModel
    let userModel: UserModel
    let unitNumber: Int
    let lessonId: String
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedModelId: String?
    
    var body: some View {
        ScrollView {
            LazyHStack {
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
        .onChange(of: selectedImage) { old,newImage in
            if let image = newImage,
               let modelId = selectedModelId {
                Task {
                     handleImageSelection(image: image, modelId: modelId, lessonId: lessonId)
                }
            }
        }
    }
    func updateModelImage(modelId: String, newImageUrl: URL, lessonId: String) async {
        // Check and update foreModels
        if let index = viewModel.foreModels.firstIndex(where: { $0.id == modelId }) {
            viewModel.foreModels[index].imageUrl = newImageUrl
        }
        
        // Check and update backModels
        if let index = viewModel.backModels.firstIndex(where: { $0.id == modelId }) {
            viewModel.backModels[index].imageUrl = newImageUrl
        }
        
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
    
    private func handleImageSelection(image: UIImage,modelId:String, lessonId: String) {
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
    private func updateModelInFirestore(modelId: String, imageUrl: URL,lessonId: String) async throws {
        let db = Db().firestore
        let lessonRef = db.collection("lessonsNew").document(lessonId)
        
        // First, get the current document
        let documentSnapshot = try await lessonRef.getDocument()
        
        guard let data = documentSnapshot.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve document data"])
        }
        
        // Get both model arrays
        guard var foreModels = data["foreModels"] as? [[String: Any]],
              var backModels = data["backModels"] as? [[String: Any]] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve models"])
        }
        
        var updatedForeModels = false
        var updatedBackModels = false
        
        // Check and update foreModels
        if let index = foreModels.firstIndex(where: { ($0["id"] as? String) == modelId }) {
            var updatedModel = foreModels[index]
            updatedModel["imageUrl"] = imageUrl.absoluteString
            foreModels[index] = updatedModel
            updatedForeModels = true
        }
        
        // Check and update backModels
        if let index = backModels.firstIndex(where: { ($0["id"] as? String) == modelId }) {
            var updatedModel = backModels[index]
            updatedModel["imageUrl"] = imageUrl.absoluteString
            backModels[index] = updatedModel
            updatedBackModels = true
        }
        
        // Update the document with the modified arrays
        var updateData: [String: Any] = [:]
        
        if updatedForeModels {
            updateData["foreModels"] = foreModels
        }
        
        if updatedBackModels {
            updateData["backModels"] = backModels
        }
        
        if !updateData.isEmpty {
            try await lessonRef.updateData(updateData)
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model ID not found in either foreModels or backModels"])
        }
    }
}

struct GListeningView: View {
    let model: GListeningModel
    let onFinished: () -> Void
    let languageCode: String
    let audioUrlDict: [String: [String:String]]
    let userModel: UserModel
    @StateObject private var viewModel = GListeningViewModel()
    @State private var showTranslations = false
    
    var languages: [String] {
        return Array(viewModel.titleModel!.textDict.keys).sorted()
    }
    
    var body: some View {
        VStack(alignment:.center) {
            HStack (alignment:.center){
                Text(viewModel.titleModel?.textDict[viewModel.languageCode!]! ?? "")
                    .font(.title2) // Larger font size
                    .fontWeight(.bold) // Adds boldness
                Button(action: {
                    viewModel.playAudio()
                }) {
                    Image(systemName: "play.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Button(action: {
                    showTranslations.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(20)
            .background(Color(.lightGray)) // Light background for the title
            .cornerRadius(8) // Rounded corners for the title container
            BackView(
                models: viewModel.backModels,
                viewModel: viewModel,
                userModel: userModel,
                unitNumber: model.unitNumber,
                lessonId: model.id
            )
            .foregroundColor(Color.black.opacity(0.5))
            
            ForeView(
                models: userModel.role == "admin" ? viewModel.foreModels : viewModel.foreModels.shuffled(),
                viewModel: viewModel,
                userModel: userModel,
                unitNumber: model.unitNumber,
                lessonId: model.id
            )
        }
        .sheet(isPresented: $showTranslations) {
            TranslationsView(titleModel: viewModel.titleModel, languages: languages)
        }
        .onAppear(){
            viewModel.backModels = model.backModels
            viewModel.foreModels = model.foreModels
            viewModel.titleModel = model.foreModels.first // Initialize titleModel
            viewModel.onFinished = onFinished
            viewModel.languageCode = languageCode
            viewModel.audioUrlDict = audioUrlDict
            setupAudioSessionForPlayback()
            viewModel.preloadPlayInitialAudio()
            viewModel.setupAudioPlayers()
        }
    }
}

private func deactivateAudioSession(completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            completion()
        } catch {
            print("❌ Failed to deactivate audio session")
            print("❌ \(error.localizedDescription)")
            completion()
        }
    }
}

private func setupAudioSessionForPlayback() {
    deactivateAudioSession {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("✅ Audio session configured for playback")
            } catch {
                print("❌ Failed to set up playback session")
                print("❌ \(error.localizedDescription)")
            }
        }
    }
}


struct TranslationsView: View {
    let titleModel: ListeningModel?
    let languages: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.self) { language in
                    VStack(alignment: .leading) {
                        Text(language)
                            .font(.headline)
                        Text(titleModel?.textDict[language] ?? "Translation not available")
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Translations")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

