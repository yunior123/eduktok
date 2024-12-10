//
//  LessonCreationView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 19/3/24.
//

import SwiftUI
import FirebaseFirestore
import AVKit

struct LessonCreationView: View {
    @State private var units: [UnitModel] = []
    @State private var isLoading = false
    @State private var selectedUnit: UnitModel?
    @State private var selectedLessonType: GLanguageSkill = .GListening
    @State private var lessons: [any LessonModel] = [] // Array to store lessons
    @State private var showErrorAlert = false // State to control error alert
    @State private var errorMessage = "" // State for error message
    
    func fetchUnits() async {
        isLoading = true  // Start loading indication
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("units").getDocuments()
            units = snapshot.documents.compactMap { document in
                guard let unitModel = UnitModel(from: document) else {
                    print("Error creating UnitModel from document")
                    return nil
                }
                return unitModel
            }
            isLoading = false  // Stop loading indication
        } catch {
            isLoading = false  // Stop loading indication
            errorMessage = "Error loading units: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    var body: some View {
        ScrollView { // Add ScrollView here
            VStack (alignment: .center) {
                Text("Create Lesson")
                    .font(.title)
                if !units.isEmpty && selectedUnit != nil {
                    let sortedUnits = units.sorted { (unit1, unit2) -> Bool in
                        let languagesOrder: [String] = ["English", "German", "French", "Spanish"]
                        guard let index1 = languagesOrder.firstIndex(of: unit1.language),
                              let index2 = languagesOrder.firstIndex(of: unit2.language) else {
                            return false // Handle if language not found in languagesOrder
                        }
                        
                        // If both units belong to the same language, sort by unit number
                        if index1 == index2 {
                            return unit1.unitNumber < unit2.unitNumber
                        } else {
                            return index1 < index2
                        }
                    }
                    
                    Picker("Select Unit", selection: $selectedUnit) {
                        ForEach(sortedUnits, id: \.id) { unit in
                            Text("\(unit.unitNumber). \(unit.title)").tag(Optional(unit))
                        }
                    }
                }
                
                Picker("Lesson Type", selection: $selectedLessonType) {
                    ForEach(GLanguageSkill.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                if selectedLessonType == .GListening {
                    ListeningLessonForm(selectedUnit: $selectedUnit)
                }
                else if selectedLessonType == .GListeningFour {
                    ListeningFourLessonForm(selectedUnit: $selectedUnit)
                }
                else if selectedLessonType == .GSpeaking {
                    SpeakingLessonForm(selectedUnit: $selectedUnit)
                }
                else if selectedLessonType == .GWriting {
                    Text("Other lesson types - Forms coming soon!")
                } else {
                    Text("Other lesson types - Forms coming soon!")
                }
                
                Spacer() // Push everything to the top
            }
            .padding(15)
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    // Optionally: Reset error state if needed
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                Task {
                    await fetchUnits()
                    if let firstUnit = units.first(where: { $0.unitNumber == 1 && $0.language == "English" }) {
                        selectedUnit = firstUnit
                    }
                }
            }
        }
    }
    
}

struct ListeningFourLessonForm: View {
    @State private var foreModels: [ListeningModel] = []
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessMessage = false
    @State private var isLoading = false
    @Binding var selectedUnit: UnitModel?
    
    var successMessageView: some View {
        Text("Lesson Created!")
            .foregroundColor(.green)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
    
    var body: some View {
        VStack (alignment: .center) {
            if let unit = selectedUnit {
                Text("Fore Models")
                MiniListeningForm(models: $foreModels, unit: unit)
            }
            
            Button("Add ListeningFour Lesson") {
                Task {
                    await createLesson()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .frame(maxWidth: .infinity)
            .disabled(isLoading)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { errorMessage = "" }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: showSuccessMessage) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSuccessMessage = false
                }
            }
        }
        .overlay(showSuccessMessage ? successMessageView : nil)
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.5)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
        )
    }
    
    func createLesson() async {
        guard foreModels.count >= 4 else {
            errorMessage = "Please add at least four fore models."
            showErrorAlert = true
            return
        }
        
        guard let unit = selectedUnit else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let lessonNumber = try await fetchHighestLessonNumber(docId: unit.id!)
            guard let lessonNumber = lessonNumber else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get Lesson Number"])
            }
            
            var lesson = GListeningFourModel(id: UUID().uuidString, lessonNumber: lessonNumber, type: .GListeningFour, foreModels: foreModels)
            
            // Upload all assets
            for i in 0..<lesson.foreModels.count {
                let model = lesson.foreModels[i]
                let imageData = model.imageData
                let audioData = model.audioData
                
                let imagePath = createImageFilePath(unit: unit, lessonNumber: lessonNumber, id: model.id)
                let audioPath = createAudioPath(unit: unit, lessonNumber: lessonNumber, id: model.id)
                
                let imageUrl = try await uploadImageToFirebaseC(image: imageData!, path: imagePath)
                let audioUrl = try await uploadAudioToFirebaseC(audio: audioData!, path: audioPath)
                
                lesson.foreModels[i].imageUrl = imageUrl
                lesson.foreModels[i].audioUrl = audioUrl
            }
            
            // Update unit with new lesson
            var updatedUnit = try await fetchUnitByDocId(docId: unit.id!)
            updatedUnit?.lessons.append(lesson)
            
            if let updatedUnit = updatedUnit {
                try await updateUnitInFirestore(unit: updatedUnit)
                foreModels.removeAll()
                showSuccessMessage = true
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update unit"])
            }
        } catch {
            errorMessage = "Failed to create lesson: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}
struct ListeningLessonForm: View {
    @State private var backModels: [ListeningModel] = []
    @State private var foreModels: [ListeningModel] = []
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessMessage = false
    @State private var isLoading = false
    @Binding var selectedUnit: UnitModel?
    
    var successMessageView: some View {
        Text("Lesson Created!")
            .foregroundColor(.green)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
    
    var body: some View {
        VStack (alignment: .center) {
            if let unit = selectedUnit {
                Text("Back Models")
                MiniListeningForm(models: $backModels, unit: unit)
                Text("Fore Models")
                MiniListeningForm(models: $foreModels, unit: unit)
            }
            
            Button("Add Listening Lesson") {
                Task {
                    await createLesson()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .frame(maxWidth: .infinity)
            .disabled(isLoading)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { errorMessage = "" }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: showSuccessMessage) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSuccessMessage = false
                }
            }
        }
        .overlay(showSuccessMessage ? successMessageView : nil)
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.5)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
        )
    }
    
    func createLesson() async {
        guard backModels.count >= 2 && foreModels.count >= 2 else {
            errorMessage = "Please add at least two back and fore models."
            showErrorAlert = true
            return
        }
        
        guard let unit = selectedUnit else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let lessonNumber = try await fetchHighestLessonNumber(docId: unit.id!)
            guard let lessonNumber = lessonNumber else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get Lesson Number"])
            }
            
            var lesson = GListeningModel(id: UUID().uuidString, lessonNumber: lessonNumber, type: .GListening, backModels: backModels, foreModels: foreModels)
            
            // Upload all assets
            func uploadModels(_ models: inout [ListeningModel]) async throws {
                for i in 0..<models.count {
                    let model = models[i]
                    let imageData = model.imageData
                    let audioData = model.audioData
                    
                    let imagePath = createImageFilePath(unit: unit, lessonNumber: lessonNumber, id: model.id)
                    let audioPath = createAudioPath(unit: unit, lessonNumber: lessonNumber, id: model.id)
                    
                    let imageUrl = try await uploadImageToFirebaseC(image: imageData!, path: imagePath)
                    let audioUrl = try await uploadAudioToFirebaseC(audio: audioData!, path: audioPath)
                    
                    models[i].imageUrl = imageUrl
                    models[i].audioUrl = audioUrl
                }
            }
            
            try await uploadModels(&lesson.backModels)
            try await uploadModels(&lesson.foreModels)
            
            // Update unit with new lesson
            var updatedUnit = try await fetchUnitByDocId(docId: unit.id!)
            updatedUnit?.lessons.append(lesson)
            
            if let updatedUnit = updatedUnit {
                try await updateUnitInFirestore(unit: updatedUnit)
                backModels.removeAll()
                foreModels.removeAll()
                showSuccessMessage = true
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update unit"])
            }
        } catch {
            errorMessage = "Failed to create lesson: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}
struct MiniListeningForm: View {
    @Binding var models: [ListeningModel]
    @State private var text: String = ""
    @State private var image: UIImage?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessMessage = false
    @State var audio: Data?
    @State private var resetAudioTrigger = false
    let unit: UnitModel
    
    var successMessageView: some View {
        Text("Model Added!")
            .foregroundColor(.green)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
    
    var body: some View {
        VStack (alignment: .center) {
            TextField("Text", text: $text)
                .frame(width: 200)
            ImageDropper(image: $image)
            AudioDropper(audio: $audio, resetTrigger: $resetAudioTrigger)
            
            Button("Add Model") {
                if text.isEmpty {
                    errorMessage = "Text cannot be empty"
                    showErrorAlert = true
                    return
                }
                guard let imageData = image?.jpegData(compressionQuality: 0.5) else {
                    errorMessage = "Failed to convert image to data"
                    showErrorAlert = true
                    return
                }
                guard let audioData = self.audio else {
                    errorMessage = "Failed to load audio"
                    showErrorAlert = true
                    return
                }
                
                let model = ListeningModel(id: UUID().uuidString, text: text, audioUrl: nil, imageUrl: nil, imageData: imageData, audioData: audioData)
                models.append(model)
                
                // Reset form
                text = ""
                image = nil
                audio = nil
                resetAudioTrigger = true  // This will trigger the reset in AudioDropper
                showSuccessMessage = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .frame(maxWidth: .infinity)
        }
        .frame(width: 200)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { errorMessage = "" }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: showSuccessMessage) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSuccessMessage = false
                }
            }
        }
        .overlay(showSuccessMessage ? successMessageView : nil)
    }
}

struct SpeakingLessonForm: View {
    @State private var models: [SpeakingModel] = []
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessMessage = false
    @State private var isLoading = false
    @Binding var selectedUnit: UnitModel?
    
    var successMessageView: some View {
        Text("Lesson Created!")
            .foregroundColor(.green)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
    
    var body: some View {
        VStack (alignment: .center) {
            Text("Speaking Models")
            if let unit = selectedUnit {
                MiniSpeakingForm(models: $models, unit: unit)
            }
            
            Button("Add Speaking Lesson") {
                Task {
                    await createLesson()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .frame(maxWidth: .infinity)
            .disabled(isLoading)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { errorMessage = "" }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: showSuccessMessage) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSuccessMessage = false
                }
            }
        }
        .overlay(showSuccessMessage ? successMessageView : nil)
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.5)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
        )
    }
    
    func createLesson() async {
        guard models.count >= 4 else {
            errorMessage = "Please add at least four speaking models."
            showErrorAlert = true
            return
        }
        
        guard let unit = selectedUnit else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let lessonNumber = try await fetchHighestLessonNumber(docId: unit.id!)
            guard let lessonNumber = lessonNumber else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get Lesson Number"])
            }
            
            var lesson = GSpeakingModel(id: UUID().uuidString, lessonNumber: lessonNumber, type: .GSpeaking, models: models)
            
            // Upload all assets
            for i in 0..<lesson.models.count {
                let model = lesson.models[i]
                let imageData = model.imageData
                let audioData = model.audioData
                
                let imagePath = createImageFilePath(unit: unit, lessonNumber: lessonNumber, id: model.id)
                let audioPath = createAudioPath(unit: unit, lessonNumber: lessonNumber, id: model.id)
                
                let imageUrl = try await uploadImageToFirebaseC(image: imageData!, path: imagePath)
                let audioUrl = try await uploadAudioToFirebaseC(audio: audioData!, path: audioPath)
                
                lesson.models[i].imageUrl = imageUrl
                lesson.models[i].audioUrl = audioUrl
            }
            
            // Update unit with new lesson
            var updatedUnit = try await fetchUnitByDocId(docId: unit.id!)
            updatedUnit?.lessons.append(lesson)
            
            if let updatedUnit = updatedUnit {
                try await updateUnitInFirestore(unit: updatedUnit)
                models.removeAll()
                showSuccessMessage = true
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update unit"])
            }
        } catch {
            errorMessage = "Failed to create lesson: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

struct MiniSpeakingForm: View {
    @Binding var models: [SpeakingModel]
    @State private var text: String = ""
    @State private var image: UIImage?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessMessage = false
    @State var audio: Data?
    @State private var resetAudioTrigger = false
    let unit: UnitModel
    
    var successMessageView: some View {
        Text("Model Added!")
            .foregroundColor(.green)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
    
    var body: some View {
        VStack (alignment: .center) {
            TextField("Text", text: $text)
                .frame(width: 200)
            ImageDropper(image: $image)
            AudioDropper(audio: $audio, resetTrigger: $resetAudioTrigger)
            
            Button("Add Model") {
                if text.isEmpty {
                    errorMessage = "Text cannot be empty"
                    showErrorAlert = true
                    return
                }
                guard let imageData = image?.jpegData(compressionQuality: 0.5) else {
                    errorMessage = "Failed to convert image to data"
                    showErrorAlert = true
                    return
                }
                guard let audioData = self.audio else {
                    errorMessage = "Failed to load audio"
                    showErrorAlert = true
                    return
                }
                
                let model = SpeakingModel(id: UUID().uuidString, text: text, audioUrl: nil, imageUrl: nil, imageData: imageData, audioData: audioData)
                models.append(model)
                
                // Reset form
                text = ""
                image = nil
                audio = nil
                resetAudioTrigger = true  // This will trigger the reset in AudioDropper
                showSuccessMessage = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .frame(maxWidth: .infinity)
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    // Optionally: Reset error state if needed
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: showSuccessMessage) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Change delay as needed
                        showSuccessMessage = false
                    }
                }
            }
            .overlay( // Add overlay for success message
                showSuccessMessage ? successMessageView : nil
            )
        }
        .frame(width: 200)
    }
}

struct AudioDropper: View {
    @State private var audioPlayer: AVAudioPlayer?
    @Binding var audio: Data?
    @State private var errorMessage: String?
    @Binding var resetTrigger: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .border(Color.gray, width: 1)
            
            VStack (alignment: .center, spacing: 10) {
                if audio == nil {
                    Text("Drop Audio File Here")
                        .font(.headline)
                } else {
                    if let audioPlayer = audioPlayer {
                        AudioPlayerView(player: audioPlayer)
                    }
                    
                    Button("Clear") {
                        clear()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(5)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .frame(width: 200, height: 200)
        .onChange(of: resetTrigger) { _, newValue in
            if newValue {
                clear()
                DispatchQueue.main.async {
                    resetTrigger = false
                }
            }
        }
        .onDrop(of: ["public.audio"], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadDataRepresentation(forTypeIdentifier: "public.audio") { data, error in
                if let data = data, error == nil {
                    do {
                        let audioPlayer = try AVAudioPlayer(data: data)
                        DispatchQueue.main.async {
                            self.audioPlayer = audioPlayer
                        }
                        audioPlayer.play()
                        audio = data
                        self.errorMessage = nil // Clear any previous error message
                    } catch {
                        DispatchQueue.main.async {
                            self.errorMessage = "Error: Unable to play audio."
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error: Unable to load audio file."
                    }
                }
            }
            return true
        }
    }
    
    private func clear() {
        audio = nil
        audioPlayer = nil
        errorMessage = nil
    }
}

struct AudioPlayerView: View {
    var player: AVAudioPlayer
    
    var body: some View {
        HStack {
            Button(action: {
                if player.isPlaying {
                    player.pause()
                } else {
                    player.play()
                }
            }) {
                Image(systemName: "play.fill")
            }
            
        }
        .padding()
    }
}

private func fetchHighestLessonNumber(docId: String) async throws -> Int? {
    let db = Firestore.firestore()
    let query = db.collection("units").document(docId)
    
    let querySnapshot = try await query.getDocument()
    
    guard let document = querySnapshot.data() else {
        return nil
    }
    
    guard let lessonsArray = document["lessons"] as? [Any] else {
        return nil // "lessons" field is missing or not an array
    }
    
    if lessonsArray.isEmpty {
        return 0
    }
    
    let lessonNumbers = lessonsArray.compactMap { lesson in
        return (lesson as? [String: Any])?["lessonNumber"] as? Int
    }
    let max = lessonNumbers.max()
    guard let max = max else {
        return nil
    }
    return  max + 1
}


//struct WritingLessonForm: View {
//    @State private var models: [CompletionCardModel] = []
//    @State private var showErrorAlert = false
//    @State private var errorMessage = ""
//    @State private var showSuccessMessage = false
//    @Binding var selectedUnit: UnitModel?
//    var successMessageView: some View {
//        Text("Lesson Created!")
//            .foregroundColor(.green)
//            .padding()
//            .background(Color(.systemBackground))
//            .cornerRadius(10)
//    }
//
//    var body: some View {
//        VStack (alignment: .center) {
//            Text("Writing Models")
//            if let unit = selectedUnit {
//                MiniWritingForm(models: $models, unit: unit)
//            }
//
//            Button("Add Writing Lesson") {
//                Task {
//                    if models.count >= 3 {  // Check for at least 3 models
//                        guard let unit = selectedUnit else { return }
//                        let lessonNumber = try await fetchHighestLessonNumber(docId: unit.id!)
//                        guard let lessonNumber = lessonNumber else {
//                            errorMessage = "Failed to get Lesson Number"
//                            showErrorAlert = true
//                            return
//                        }
//                        let lesson = GWritingModel(lessonNumber: lessonNumber, id: UUID().uuidString, type: .GWriting, completionCards: models)
//
//                        do {
//                            let updatedUnit = try await fetchUnitByDocId(docId: unit.id!)
//                            guard var updatedUnit = updatedUnit else {
//                                errorMessage = "Selected unit not found."
//                                showErrorAlert = true
//                                return
//                            }
//
//                            updatedUnit.lessons.append(lesson)
//
//                            try await updateUnitInFirestore(unit: updatedUnit)
//                            showSuccessMessage = true
//                        } catch {
//                            errorMessage = "Failed to update unit: \(error.localizedDescription)"
//                            showErrorAlert = true
//                        }
//                        showSuccessMessage = true
//                    } else {
//                        // Handle the case where the validation fails
//                        errorMessage = "Please add at least 3 writing models."
//                        showErrorAlert = true
//                    }
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.blue)
//            .buttonBorderShape(.roundedRectangle(radius: 20))
//            .frame(maxWidth: .infinity)
//        }
//        .alert("Error", isPresented: $showErrorAlert) {
//            Button("OK") {
//                // Optionally: Reset error state if needed
//                errorMessage = ""
//            }
//        } message: {
//            Text(errorMessage)
//        }
//        .onChange(of: showSuccessMessage) { _, newValue in
//            if newValue {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    showSuccessMessage = false
//                }
//            }
//        }
//        .overlay(
//            showSuccessMessage ? successMessageView : nil
//        )
//    }
//}

//struct MiniWritingForm: View {
//    @Binding var models: [CompletionCardModel]
//    @State private var text: String = ""
//    @State private var image: UIImage?
//    @State private var showErrorAlert = false
//    @State private var errorMessage = ""
//    @State private var showSuccessMessage = false
//    @State var audio: Data?
//    let unit: UnitModel
//
//    var successMessageView: some View {
//        Text("Model Added!")
//            .foregroundColor(.green)
//            .padding()
//            .background(Color(.systemBackground))
//            .cornerRadius(10)
//    }
//
//    var body: some View {
//        VStack (alignment: .center) {
//            TextField("Text", text: $text)
//                .frame(width: 200)
//            ImageDropper(image: $image)
//            AudioDropper(audio: $audio)
//
//            Button("Add Model") {
//                Task {
//                    do {
//                        if text.isEmpty {
//                            errorMessage = "Text cannot be empty"
//                            showErrorAlert = true
//                            return
//                        }
//                        guard let imageData = image?.jpegData(compressionQuality: 0.5) else {
//                            errorMessage = "Failed to convert image to data"
//                            showErrorAlert = true
//                            return
//                        }
//                        let id = UUID().uuidString
//                        let lessonNumber = try await fetchHighestLessonNumber(docId: unit.id!)
//                        guard let lessonNumber = lessonNumber else {
//                            errorMessage = "Failed to get Lesson Number"
//                            showErrorAlert = true
//                            return
//                        }
//                        let imageUrl = try await uploadImageToFirebase(image: imageData,path:"images/unit_\(unit.unitNumber)_language_\(unit.language)_lesson_\(lessonNumber)_id_\(id).jpg" )
//                        guard let audio = self.audio else {
//                            errorMessage = "Failed to load audio"
//                            showErrorAlert = true
//                            return
//                        }
//
//                        let audioUrl = try await uploadAudioToFirebase(audio: audio, path: "audios/unit_\(unit.unitNumber)_language_\(unit.language)_lesson_\(lessonNumber)_id_\(id).mp3")
//
////                        let model = CompletionCardModel(id: id, wordsBlocks: <#T##[Int : String]#>, solutionsIndexes: <#T##[Int]#>, audioUrl: <#T##URL#>, imageUrl: <#T##URL#>)
////                        let model = SpeakingModel(id: id, text: text, audioUrl: audioUrl, imageUrl: imageUrl)
////                        models.append(model)
//
//                        // Success Logic:
//                        text = "" // Reset text field
//                        image = nil // Optionally reset image
//                        showSuccessMessage = true // Show success
//                    } catch {
//                        errorMessage = "Error creating model: \(error.localizedDescription)"
//                        showErrorAlert = true
//                    }
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.blue)
//            .buttonBorderShape(.roundedRectangle(radius: 20))
//            .frame(maxWidth: .infinity)
//            .alert("Error", isPresented: $showErrorAlert) {
//                Button("OK") {
//                    // Optionally: Reset error state if needed
//                    errorMessage = ""
//                }
//            } message: {
//                Text(errorMessage)
//            }
//            .onChange(of: showSuccessMessage) { _, newValue in
//                if newValue {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Change delay as needed
//                        showSuccessMessage = false
//                    }
//                }
//            }
//            .overlay( // Add overlay for success message
//                showSuccessMessage ? successMessageView : nil
//            )
//        }
//        .frame(width: 200)
//    }
//}
