//
//  GSpeakingView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import SwiftUI
import AVKit
import Speech
import AVFoundation

extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}

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
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { oldImage, newImage in
                print("Selected Image Changed")
                if let image = newImage,
                   let modelId = selectedModelId {
                    handleImageSelection(image: image, modelId: modelId, lessonId: model.id)
                }
            }
        }
        .onAppear {
            viewModel.models = userModel.role == "admin" ? model.models : model.models.shuffled()
            viewModel.onFinished = onFinished
            viewModel.languageCode = languageCode
            viewModel.audioUrlDict = audioUrlDict
            activeCardIndex = 0
            setupAudioSessionForPlayAndRecord()
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
    
    private func setupAudioSessionForPlayAndRecord() {
        deactivateAudioSession {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    print("✅ Audio session configured for play and record")
                } catch {
                    print("❌ Failed to set up play and record session")
                    print("❌ \(error.localizedDescription)")
                }
            }
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
                    unitNumber: model.unitNumber,
                    id: lessonId + modelId
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

struct SCardView: View {
    let model: SpeakingModel
    let language: Locale
    let index: Int
    
    @Binding var activeCardIndex: Int
    
    @ObservedObject var viewModel: GSpeakingViewModel
    @State private var showSuccess = false
    @State private var showRetry = false
    @State private var player: AVAudioPlayer?
    @State private var successPlayer: AVAudioPlayer?
    @State private var errorPlayer: AVAudioPlayer?
    @State private var micActivePlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    @StateObject private var speechRecognizer: StreamingSpeechRecognizerViewModel
    
    init(model: SpeakingModel, language: Locale, index: Int, activeCardIndex: Binding<Int>, viewModel: GSpeakingViewModel) {
        self.model = model
        self.language = language
        self.index = index
        self._activeCardIndex = activeCardIndex
        self.viewModel = viewModel
        _speechRecognizer = StateObject(
            wrappedValue: StreamingSpeechRecognizerViewModel(
                language: language
            )
        )
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text(model.textDict[viewModel.languageCode!]!)
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    if !model.completed { // Disable play button if completed
                        Button(action: {
                            playAudio()
                        }) {
                            Image(systemName: "play.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                HStack {
                    Text(speechRecognizer.transcription)
                        .font(.title)
                        .frame(minHeight: 50)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .animation(.easeInOut, value: speechRecognizer.transcription)
                    Spacer()
                    if !model.completed { // Disable button if completed
                        VStack {
                            Button(action: toggleRecognition) {
                                Image(systemName: speechRecognizer.isListening  ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(speechRecognizer.isListening  ? .red : .blue)
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .center) {
                if speechRecognizer.isListening {
                    UndulationView()
                        .frame(width: 60, height: 60)
                }
            }
            CachedAsyncImage(url: model.imageUrl!, placeholder: Image(systemName: "photo"))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .shadow(radius: 3)
        .opacity(model.completed ? 0.8 : 1.0)
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
                
                do {
                    player = try AVAudioPlayer(data: data)
                    player?.prepareToPlay()
                    player?.volume = 1.0
                } catch {
                    print("Error initializing AVAudioPlayer: \(error.localizedDescription)")
                }
            }.resume()
            
            loadAudioFile(filename: "success", player: &successPlayer)
            if successPlayer != nil {
            } else {
                print("Failed to load successPlayer.")
            }
            
            loadAudioFile(filename: "error", player: &errorPlayer)
            if errorPlayer != nil {
            } else {
                print("Failed to load errorPlayer.")
            }
            
            loadAudioFile(filename: "mic-active", player: &micActivePlayer)
            if micActivePlayer != nil {
            } else {
                print("Failed to load micActivePlayer.")
            }
            if index == 0 {
                toggleRecognition() // Start recognition for the first card when it appears
            }
            
        }
        .onDisappear {
            speechRecognizer.stopRecognition()
            micActivePlayer?.stop()
            errorPlayer?.stop()
            successPlayer?.stop()
            micActivePlayer = nil
            errorPlayer = nil
            successPlayer = nil
        }
        .onChange(of: activeCardIndex) { _, newValue in
            if index == newValue {
                toggleRecognition()
            }
        }
        .overlay(alignment: .top) {
            if showSuccess {
                Text("Success!")
                    .font(.headline)
                    .padding()
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.opacity.animation(.easeInOut))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showSuccess = false }
                        }
                    }
            } else if showRetry {
                Text("Try again!")
                    .font(.headline)
                    .padding()
                    .background(.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.opacity.animation(.easeInOut))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showRetry = false }
                        }
                    }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if model.completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .opacity(0.8) // Adjust opacity here
            }
        }
    }
    
    
    private func loadAudioFile(filename: String, player: inout AVAudioPlayer?) {
        if let audioData = NSDataAsset(name: filename)?.data {
            do {
                player = try AVAudioPlayer(data: audioData)
                player?.prepareToPlay()
                player?.volume = 1.0
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found: \(filename)")
        }
    }
    
    func playAudio() {
        guard let player = player else {
            print("Audio player is nil.")
            return
        }
        
        if player.isPlaying {
            print("Audio is already playing.")
            return
        }
        
        print("Playing audio...")
        DispatchQueue.main.async {
            player.play()
        }
        print("Audio duration: \(player.duration) seconds")
    }
    
    
    func trimmed(_ string: String) -> String {
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func validateSpeech() async {
        let transcript = speechRecognizer.transcription
        let langCode = viewModel.languageCode!
        let text = model.textDict[langCode]!;
        let trimmedText = trimmed(text.lowercased()).trimmingCharacters(in: .punctuationCharacters)
        let trimmedTranscript = trimmed(transcript.lowercased()).trimmingCharacters(in: .punctuationCharacters)
        let match = areStringsSimilar(trimmedText, trimmedTranscript)
        
        if match {
            showSuccessMessage()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            viewModel.markCardCompleted(id: model.id)
            DispatchQueue.main.async {
                activeCardIndex += 1 // Move to the next card
            }
        } else {
            showRetryMessage()
        }
    }
    
    func areStringsSimilar(_ str1: String, _ str2: String) -> Bool {
        // Function to calculate Levenshtein distance
        func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
            let m = s1.count
            let n = s2.count
            var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
            
            for i in 0...m {
                matrix[i][0] = i
            }
            
            for j in 0...n {
                matrix[0][j] = j
            }
            
            for i in 1...m {
                for j in 1...n {
                    if s1[s1.index(s1.startIndex, offsetBy: i - 1)] == s2[s2.index(s2.startIndex, offsetBy: j - 1)] {
                        matrix[i][j] = matrix[i - 1][j - 1]
                    } else {
                        matrix[i][j] = min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + 1)
                    }
                }
            }
            
            return matrix[m][n]
        }
        
        let distance = levenshteinDistance(str1, str2)
        let maxLength = max(str1.count, str2.count)
        let similarity = 1.0 - Double(distance) / Double(maxLength)
        
        return similarity >= 0.85
    }
    
    func showSuccessMessage() {
        showSuccess = true
        DispatchQueue.main.async {
            successPlayer?.play()
        }
    }
    
    func showRetryMessage() {
        showRetry = true
        DispatchQueue.main.async {
            errorPlayer?.play()
        }
        
    }
    
    func toggleRecognition() {
        DispatchQueue.main.async {
            speechRecognizer.toggleRecognition()
            Task {
                if speechRecognizer.isListening {
                    micActivePlayer?.play()
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } else {
                    await validateSpeech()
                }
            }
            
        }
    }
}




struct UndulationView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<5) { i in
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .scaleEffect(animate ? 1.0 : 0.5)
                        .opacity(animate ? 0.0 : 1.0)
                        .animation(Animation.easeOut(duration: 1.5).repeatForever().delay(Double(i) * 0.3), value: animate)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            animate = true
        }
        .onDisappear {
            animate = false
        }
    }
}

