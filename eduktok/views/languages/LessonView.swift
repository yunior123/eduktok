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
                guard let _ = data["id"] as? String,
                      let _ = data["lessonNumber"] as? Int,
                      let _ = data["audioUrlDict"] as? [String: [String:String]] else {
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
                            ScrollViewReader { scrollProxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        // Add leading spacer for initial padding
                                        ForEach(0..<lessons.count, id: \.self) { lessonIndex in
                                            let isLessonCompleted = ((userModel.languageProgress?[userModel.learningLanguage ?? selectedLanguage]?[unit.id!]?[getLessonId(index: lessonIndex)]) != nil)
                                            
                                            LessonButton(lessonNumber: lessonIndex + 1,
                                                         isCompleted: isLessonCompleted,
                                                         currentLesson: currentLesson)
                                            .id(lessonIndex)
                                            .onTapGesture {
                                                withAnimation {
                                                    currentLesson = lessonIndex
                                                    scrollProxy.scrollTo(lessonIndex, anchor: .center)
                                                }
                                            }
                                        }
                                        
                                        // Add trailing spacer for final padding
                                        Spacer()
                                            .frame(width: max(0, (geometry.size.width - 60) / 2))
                                    }
                                    .padding()
                                    .frame(minWidth: geometry.size.width)
                                }
                                .onChange(of: currentLesson) { old, newLesson in
                                    withAnimation {
                                        scrollProxy.scrollTo(newLesson, anchor: .center)
                                    }
                                }
                                .onAppear {
                                    // Center the initial lesson after a brief delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            scrollProxy.scrollTo(currentLesson, anchor: .center)
                                        }
                                    }
                                }
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
        @Environment(\.dismiss) private var dismiss
        
        // Success phrases in different languages
        private let successPhrases: [String: (congrats: String, message: String)] = [
            "en": ("Amazing!", "You've mastered this unit!"),

        ]
        
        private var currentLanguagePhrases: (congrats: String, message: String) {
            successPhrases["en"]!
        }
        
        var body: some View {
            VStack(spacing: 24) {
                // Top celebration section
                VStack(spacing: 16) {
                    ZStack {
                        // Pulsating background rings
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                .frame(width: 80 + CGFloat(i * 30),
                                       height: 80 + CGFloat(i * 30))
                                .scaleEffect(1 + 0.1 * sin(Double(i) * .pi / 2))
                                .animation(.easeInOut(duration: 1.5).repeatForever(),
                                          value: UUID())
                        }
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce)
                    }
                    .frame(height: 120)
                    
                    // Success text in both languages
                    VStack(spacing: 8) {
                        Text(currentLanguagePhrases.congrats)
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                        
                        Text(currentLanguagePhrases.message)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Progress Stats
                HStack(spacing: 20) {
                    StatView(
                        value: "\(lessons.count)",
                        label: "Lessons",
                        icon: "book.fill",
                        color: .blue
                    )
                    
                    StatView(
                        value: "100%",
                        label: "Complete",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                
                // Motivational message
                VStack(spacing: 4) {
                    Text("🎯 Keep up the great work!")
                        .font(.headline)
                    Text("Your language skills are getting stronger every day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            try await resetUnitProgress()
                            dismiss()
                        }
                    }) {
                        Label("Practice Again", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { dismiss() }) {
                        Label("Continue Learning", systemImage: "arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(24)
            .background(Material.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
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

    // Supporting Views
    struct StatView: View {
        let value: String
        let label: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                VStack(spacing: 4) {
                    Text(value)
                        .font(.title2.bold())
                        .foregroundColor(color)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
