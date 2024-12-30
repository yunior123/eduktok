//
//  GMainView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import SwiftUI
import AVFoundation
import ConfettiSwiftUI

struct LessonView: View {
    let unit: UnitModel
    let userModel: UserModel
    let selectedLanguage: String
    @State private var currentLesson = 0
    @State private var isCompleted = false
    @State private var counter: Int = 0
    @State private var lessons: [any LessonModel] = []
    @State private var isLoading = true
    
    @State private var levelWinAudioPlayer: AVAudioPlayer?
    
    init(unit: UnitModel, userModel: UserModel, selectedLanguage: String) {
        self.unit = unit
        self.userModel = userModel
        self.selectedLanguage = selectedLanguage
    }
    
    private func getLessonNumber(from lesson: any LessonModel) -> Int {
        switch lesson {
        case let listening as GListeningModel:
            return listening.lessonNumber
        case let speaking as GSpeakingModel:
            return speaking.lessonNumber
        case let listeningFour as GListeningFourModel:
            return listeningFour.lessonNumber
        default:
            return 0
        }
    }
    
    private func loadLessons() async {
        let db = Db()
        do {
            let documents = try await db.fetchLessonsForUnit(unitNumber: unit.unitNumber)
            var loadedLessons: [any LessonModel] = []
            
            for document in documents {
                guard let data = document.data() else {
                    print("❌ Failed to get document data for document ID: \(document.documentID)")
                    continue
                }
                
                guard let type = data["type"] as? String else {
                    print("❌ Missing or invalid 'type' field for document ID: \(document.documentID)")
                    continue
                }
                
                guard let skill = GLanguageSkill(rawValue: type) else {
                    print("❌ Invalid skill type '\(type)' for document ID: \(document.documentID)")
                    continue
                }
                
                // Verify required common fields exist before creating models
                guard let id = data["id"] as? String,
                      let lessonNumber = data["lessonNumber"] as? Int,
                      let audioUrlDict = data["audioUrlDict"] as? [String: [String:String]] else {
                    print("❌ Missing required fields for document ID: \(document.documentID)")
                    continue
                }
                
                let lesson: (any LessonModel)?
                
                switch skill {
                case .GListening:
                    lesson = GListeningModel(from: data)
                    
                case .GSpeaking:
                    lesson = GSpeakingModel(from: data)
                    
                case .GListeningFour:
                    lesson = GListeningFourModel(from: data)
                }
                
                if let lesson = lesson {
                    loadedLessons.append(lesson)
                } else {
                    print("❌ Failed to create lesson model for document ID: \(document.documentID)")
                }
            }
            
            // Sort lessons by lessonNumber to ensure correct order
            loadedLessons.sort {
                getLessonNumber(from: $0) < getLessonNumber(from: $1)
            }
            
            await MainActor.run {
                self.lessons = loadedLessons
                self.isLoading = false
                if let firstIncompleteIndex = findFirstIncompleteLessonIndex() {
                    self.currentLesson = firstIncompleteIndex
                }
            }
        } catch {
            print("Error loading lessons: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading lessons...")
            } else if lessons.isEmpty {
                NoLessonsView()
            } else {
                VStack {
                    let currentLessonModel = lessons[currentLesson]
                    let langCode = convertToLanguageCode(selectedLanguage)!
                    let audioDict = currentLessonModel.audioUrlDict
                    
                    if isCompleted || isUnitComplete() {
                        CompletionView(
                            userModel: userModel,
                            unit: unit,
                            selectedLanguage: selectedLanguage,
                            lessons: lessons
                        )
                        .confettiCannon(counter: $counter)
                        .onAppear {
                            startAudioLevelWin()
                            counter += 4
                            currentLesson = 0
                        }
                    } else {
                        // Your existing lesson type checks and views...
                        if let listeningModel = currentLessonModel as? GListeningModel {
                            GListeningView(model: listeningModel,
                                           onFinished: nextView,
                                           languageCode: langCode,
                                           audioUrlDict: audioDict,
                                           userModel: userModel)
                                .id(currentLesson)
                        } else if let listeningModel = currentLessonModel as? GListeningFourModel {
                            GListeningFourView(model: listeningModel,
                                               onFinished: nextView,
                                               languageCode: langCode,
                                               audioUrlDict: audioDict,
                                               userModel: userModel)
                                .id(currentLesson)
                        } else if let speakingModel = currentLessonModel as? GSpeakingModel {
                            GSpeakingView(model: speakingModel,
                                          onFinished: nextView,
                                          languageCode: langCode,
                                          audioUrlDict: audioDict,
                                          userModel: userModel)
                                .id(currentLesson)
                        }
                    }
                    
                    // Lesson navigation buttons
                    if !lessons.isEmpty && !isUnitComplete() {
                        GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(0..<lessons.count, id: \.self) { lessonIndex in
                                        let isLessonCompleted = ((userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage]?[unit.id!]?[getLessonId(index: lessonIndex)]) != nil)
                                        
                                        LessonButton(lessonNumber: lessonIndex + 1,
                                                     isCompleted: isLessonCompleted,
                                                     currentLesson: currentLesson)
                                        .onTapGesture {
                                            currentLesson = lessonIndex
                                        }
                                    }
                                }
                                .padding()
                                .frame(minWidth: geometry.size.width, alignment: .center)
                            }
                        }
                        .frame(height: 80)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadLessons()
            }
        }
    }
    
    private func getLessonId(index: Int) -> String {
        return lessons[index].id
    }
    
    private func findFirstIncompleteLessonIndex() -> Int? {
        guard let languageProgress = userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage],
              let unitProgress = languageProgress[unit.id!] else { return nil }
        
        for lessonIndex in 0..<lessons.count {
            let lessonId = getLessonId(index: lessonIndex)
            if unitProgress[lessonId] == nil { // Check if not marked complete
                return lessonIndex
            }
        }
        return nil // All lessons are complete
    }
    
    private func startAudioLevelWin() {
        
        if let audioData = NSDataAsset(name: "level-win")?.data {
            do {
                levelWinAudioPlayer = try AVAudioPlayer(data: audioData)
                levelWinAudioPlayer?.prepareToPlay()
                levelWinAudioPlayer?.volume = 1.0
                levelWinAudioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }
        else {
            print("Sound level-win file not found")
        }
    }
    
    func nextView() {
        Task {
            if currentLesson < lessons.count - 1 {
                currentLesson += 1
                await updateLanguageProgress(completedLessonIndex: currentLesson - 1)
            } else {
                await updateLanguageProgress(completedLessonIndex: currentLesson)
            }
            if isUnitComplete() {
                isCompleted = true
            }
        }
    }
    
    private func isUnitComplete() -> Bool {
        guard let languageProgress = userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage],
              let unitProgress = languageProgress[unit.id!] else { return false }
        
        for lessonIndex in 0..<lessons.count {
            let lessonId = getLessonId(index: lessonIndex)
            if unitProgress[lessonId] == nil {
                return false // Incomplete lesson found
            }
        }
        return true // All lessons complete
    }
    
    
    func updateLanguageProgress(completedLessonIndex: Int) async -> Void {
        let db = Db()
        do {
            let updatedUser = try await db.findUser(email: userModel.email)
            guard let userModel = updatedUser else {
                return
            }
            var languageData = userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage] ?? [:]
            var unitData = languageData[unit.id!] ?? [:]
            let id = getLessonId(index: completedLessonIndex)
            unitData[id] = true // Mark lesson as completed
            languageData[unit.id!] = unitData
            var languageProgress = userModel.languageProgress ?? [:]
            languageProgress[userModel.learningLanguage ?? selectedLanguage] = languageData
            let newUser = userModel.copyWith(languageProgress: languageProgress)
            do {
                try await db.updateUser(user: newUser)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
    
    struct CompletionView: View {
        let userModel: UserModel
        let unit: UnitModel
        let selectedLanguage: String
        let lessons: [any LessonModel]
        
        var body: some View {
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("All Done!")
                    .font(.headline)
                Button("Restart Unit") {
                    Task {
                        try await resetUnitProgress()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        
        private func resetUnitProgress() async throws {
            let db = Db()
            guard var languageData = userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage] else { return }
            
            var unitData = languageData[unit.id!] ?? [:]
            for lessonIndex in 0..<lessons.count {
                unitData[lessons[lessonIndex].id] = nil // Clear lesson data
            }
            languageData[unit.id!] = unitData
            var languageProgress = userModel.languageProgress ?? [:]
            languageProgress[userModel.learningLanguage ?? selectedLanguage] = languageData
            let newUser = userModel.copyWith(languageProgress: languageProgress)
            try await db.updateUser(user: newUser)
        }
    }
    
    struct LessonButton: View {
        let lessonNumber: Int
        let isCompleted: Bool
        let currentLesson: Int // Add a property to track the current lesson
        
        var body: some View {
            ZStack {
                if lessonNumber - 1 == currentLesson {
                    // Show the border if this is the current lesson
                    Circle()
                        .stroke(.blue, lineWidth: 3) // Blue border for the current lesson
                        .frame(width: 40, height: 40) // Slightly larger for visual clarity
                }
                
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray)
                    .frame(width: 30, height: 30)
                
                Text("\(lessonNumber)")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}

struct NoLessonsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Lessons Available")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("This unit doesn't have any lessons yet")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

//
//struct LessonView: View {
//    let unit: UnitModel
//    let userModel: UserModel
//    let selectedLanguage: String
//    @State private var currentLesson = 0
//    @State private var isCompleted = false
//    @State private var counter: Int = 0
//
//    @State private var levelWinAudioPlayer: AVAudioPlayer?
//
//    init(unit: UnitModel, userModel: UserModel, selectedLanguage: String) {
//        self.unit = unit
//        self.userModel = userModel
//        self.selectedLanguage = selectedLanguage
//
//        // Find first incomplete lesson
//        if let firstIncompleteIndex = findFirstIncompleteLessonIndex() {
//            _currentLesson = State(initialValue: firstIncompleteIndex)
//        }
//    }
//
//    @State private var showingDelSuccessMessage = false
//
//    var body: some View {
//
//        VStack {
//            let currentLessonModel = unit.lessons[$currentLesson.wrappedValue]
//            let langCode = convertToLanguageCode(selectedLanguage)!
//            let audioDict = currentLessonModel.audioUrlDict
//
//            if $isCompleted.wrappedValue || isUnitComplete() {
//                CompletionView(userModel: userModel, unit: unit, selectedLanguage: selectedLanguage)
//                    .confettiCannon(counter: $counter) // Trigger confetti
//                    .onAppear {
//                        startAudioLevelWin()
//                        counter += 4
//                        currentLesson = 0
//                    }
//            } else if let listeningModel = currentLessonModel as? GListeningModel {
//                GListeningView(model: listeningModel,
//                               onFinished: nextView,
//                               languageCode: langCode,
//                               audioUrlDict: audioDict
//                )
//                    .id(currentLesson)
//            } else if let listeningModel = currentLessonModel as? GListeningFourModel {
//                GListeningFourView(model: listeningModel,
//                                   onFinished: nextView,
//                                   languageCode: langCode,
//                                   audioUrlDict: audioDict
//                )
//                    .id(currentLesson)
//            } else if let speakingModel = currentLessonModel as? GSpeakingModel {
//                GSpeakingView(
//                    model: speakingModel,
//                    onFinished: nextView,
//                    languageCode: langCode,
//                    audioUrlDict: audioDict
//                )
//                .id(currentLesson)
//            }
//
//            if !(isUnitComplete()) {
//                GeometryReader { geometry in
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 15) {
//                            ForEach(0...unit.lessons.count - 1, id: \.self) { lessonIndex in
//                                let isLessonCompleted = ((userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage]?[unit.id!]?[getLessonId(index: lessonIndex)]) != nil)
//
//                                LessonButton(lessonNumber: lessonIndex + 1, isCompleted: isLessonCompleted, currentLesson: currentLesson)
//                                    .onTapGesture {
//                                        currentLesson = lessonIndex
//                                    }
//                            }
//                        }
//                        .padding()
//                        .frame(minWidth: geometry.size.width, alignment: .center)
//                    }
//                }
//                .frame(height: 80) // Adjust height as needed
//            }
//
//            if showingDelSuccessMessage {
//                Text("Lesson deleted successfully!")
//                    .foregroundColor(.green)
//                    .padding()
//            }
//
//        }
//    }
//
//
//    private func findFirstIncompleteLessonIndex() -> Int? {
//        guard let languageProgress = userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage],
//              let unitProgress = languageProgress[unit.id!] else { return nil }
//
//        for lessonIndex in 0..<unit.lessons.count {
//            let lessonId = getLessonId(index: lessonIndex)
//            if unitProgress[lessonId] == nil { // Check if not marked complete
//                return lessonIndex
//            }
//        }
//        return nil // All lessons are complete
//    }
//
//    private func getLessonId(index: Int) -> String {
//        return unit.lessons[index].id
//    }
//
//    private func startAudioLevelWin() {
//
//        if let audioData = NSDataAsset(name: "level-win")?.data {
//            do {
//                levelWinAudioPlayer = try AVAudioPlayer(data: audioData)
//                levelWinAudioPlayer?.prepareToPlay()
//                levelWinAudioPlayer?.volume = 1.0
//                levelWinAudioPlayer?.play()
//            } catch {
//                print("Error playing sound: \(error.localizedDescription)")
//            }
//        }
//        else {
//            print("Sound level-win file not found")
//        }
//    }
//
//    func nextView() {
//        Task {
//            if currentLesson < unit.lessons.count - 1 {
//                currentLesson += 1
//                await updateLanguageProgress(completedLessonIndex: currentLesson - 1)
//            } else {
//                await updateLanguageProgress(completedLessonIndex: currentLesson)
//            }
//            if isUnitComplete() {
//                isCompleted = true
//            }
//        }
//    }
//
//    private func isUnitComplete() -> Bool {
//        guard let languageProgress = userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage],
//              let unitProgress = languageProgress[unit.id!] else { return false }
//
//        for lessonIndex in 0..<unit.lessons.count {
//            let lessonId = getLessonId(index: lessonIndex)
//            if unitProgress[lessonId] == nil {
//                return false // Incomplete lesson found
//            }
//        }
//        return true // All lessons complete
//    }
//
//
//    func updateLanguageProgress(completedLessonIndex: Int) async -> Void {
//        let db = Db()
//        do {
//            let updatedUser = try await db.findUser(email: userModel.email)
//            guard let userModel = updatedUser else {
//                return
//            }
//            var languageData = userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage] ?? [:]
//            var unitData = languageData[unit.id!] ?? [:]
//            let id = getLessonId(index: completedLessonIndex)
//            unitData[id] = true // Mark lesson as completed
//            languageData[unit.id!] = unitData
//            var languageProgress = userModel.languageProgress ?? [:]
//            languageProgress[userModel.learningLanguage ?? selectedLanguage] = languageData
//            let newUser = userModel.copyWith(languageProgress: languageProgress)
//            do {
//                try await db.updateUser(user: newUser)
//            }
//            catch {
//                print(error.localizedDescription)
//            }
//        }
//        catch {
//            print(error.localizedDescription)
//        }
//
//    }
//
//    struct CompletionView: View {
//        let userModel: UserModel
//        let unit: UnitModel
//        let selectedLanguage: String
//        var body: some View {
//            VStack {
//                Image(systemName: "checkmark.circle.fill")
//                    .font(.largeTitle)
//                    .foregroundColor(.green)
//                Text("All Done!")
//                    .font(.headline)
//                Button("Restart Unit") {
//                    Task {
//                        try await resetUnitProgress(userModel: userModel, unit: unit, selectedLanguage: selectedLanguage)
//                    }
//                }
//                .buttonStyle(.borderedProminent)
//            }
//            .padding()
//            .background(.ultraThinMaterial) // Nice effect
//        }
//    }
//
//    struct LessonButton: View {
//        let lessonNumber: Int
//        let isCompleted: Bool
//        let currentLesson: Int // Add a property to track the current lesson
//
//        var body: some View {
//            ZStack {
//                if lessonNumber - 1 == currentLesson {
//                    // Show the border if this is the current lesson
//                    Circle()
//                        .stroke(.blue, lineWidth: 3) // Blue border for the current lesson
//                        .frame(width: 40, height: 40) // Slightly larger for visual clarity
//                }
//
//                Circle()
//                    .fill(isCompleted ? Color.green : Color.gray)
//                    .frame(width: 30, height: 30)
//
//                Text("\(lessonNumber)")
//                    .foregroundColor(.white)
//                    .font(.headline)
//            }
//        }
//    }
//
//}


//    func deleteLesson(unitId: String, lessonId: String, lessonNumber: Int) async throws {
//        let db = Db()
//        do {
//            try await db.removeLessonFromUnit(unitId: unitId, lessonId: lessonId, unit: unit, lessonNumber: lessonNumber)
//            // Handle successful deletion
//            print("Lesson deleted successfully!")
//            // Show success message to user
//            showingDelSuccessMessage = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                self.showingDelSuccessMessage = false
//            }
//        } catch let error {
//            print("Error deleting lesson: \(error.localizedDescription)")
//            // Handle potential errors during deletion
//        }
//    }
//            if UIDevice.current.userInterfaceIdiom == .pad {
//                if userModel.role == "admin" {
//                    Button(action: {
//                        Task {
//                            try? await deleteLesson(unitId: unit.id!, lessonId: getLessonId(index: currentLesson), lessonNumber: currentLesson)
//                            // If successful deletion, potentially adjust currentLesson or refresh data
//                        }
//                    }, label: {
//                        Image(systemName: "minus.circle")
//                            .foregroundColor(.red)
//                    })
//                }
//            }
