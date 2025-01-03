//
//  GWritingView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

//import SwiftUI
//import AVKit
//
//struct GWritingView: View {
//    let model: GWritingModel
//    let onFinished: () -> Void
//    @StateObject private var viewModel = GWritingViewModel()
//    
//    var body: some View {
//        VStack {
//            ScrollView {
//                ForEach(viewModel.models, id: \.self) { cardModel in
//                    CompletionCardView(model: cardModel, viewModel: viewModel)
//                    .padding()
//                }
//            }
//            .padding([.top, .leading, .trailing])
//        }
//        .onAppear {
//            viewModel.models = model.completionCards
//            viewModel.onFinished = onFinished
//        }
//    }
//}
//
///// ex: wordsBlocks: { 1:  She is, 2: running, 3: by the, 4: river} ; solutionsIndexes: [2, 4]
//struct CompletionCardView : View {
//    let model: CompletionCardModel
//    @State private var paragraph: String = ""
//    @State private var showSnackbar = false
//    @State private var snackbarMessage = ""
//    @ObservedObject var viewModel: GWritingViewModel
//
//    func checkSolution(_ i: Int, _ updatedParagraph: String) -> Bool? {
//        let completedParagraphTill = createCompletedParagraphTill(i: i)
//        let condition = updatedParagraph == completedParagraphTill
//        if updatedParagraph == createCompletedParagraph() {
//            viewModel.markCardCompleted(id: model.id)
//        }
//        return condition
//    }
//    
//    func createCompletedParagraphTill(i: Int) -> String {
//        var updatedParagraph = ""
//        for index in 0...model.wordsBlocks.count - 1 {
//            if let word = model.wordsBlocks[index] {
//                if model.solutionsIndexes.contains(index) && index > i {
//                    updatedParagraph.append(" _________ ")
//                } else {
//                    updatedParagraph.append(" \(word) ")
//                }
//            }
//        }
//        return updatedParagraph
//    }
//
//    func createCompletedParagraph() -> String {
//        var updatedParagraph = ""
//        for index in 0...model.wordsBlocks.count - 1 {
//            if let word = model.wordsBlocks[index] {
//                    updatedParagraph.append(" \(word) ")
//            }
//        }
//        return updatedParagraph
//    }
//    
//    func createStaticParagraph() -> String {
//        var updatedParagraph = ""
//        for index in 0...model.wordsBlocks.count - 1 {
//            if let word = model.wordsBlocks[index] {
//                if model.solutionsIndexes.contains(index) {
//                    updatedParagraph.append(" _________ ")
//                   
//                } else {
//                    updatedParagraph.append(" \(word) ")
//                }
//            }
//        }
//        return updatedParagraph
//    }
//    
//    func updateParagraph() {
//        paragraph = createStaticParagraph()
//    }
//    
//    @State private var player: AVAudioPlayer?
//    @State private var successSoundPlayer: AVAudioPlayer?
//    @State private var errorSoundPlayer: AVAudioPlayer?
//    
//    func setupAudioPlayers() {
//        if let audioData = NSDataAsset(name: "success")?.data {
//            do {
//                successSoundPlayer = try AVAudioPlayer(data: audioData)
//            } catch {
//                print("Error playing sound: \(error.localizedDescription)")
//            }
//        }
//        else {
//            print("Sound success file not found")
//        }
//        if let audioData = NSDataAsset(name: "error")?.data {
//            do {
//                errorSoundPlayer = try AVAudioPlayer(data: audioData)
//            } catch {
//                print("Error playing sound: \(error.localizedDescription)")
//            }
//        }
//        else {
//            print("Sound error file not found")
//        }
//    }
//    
//    var body: some View {
//        LazyVStack {
//            ScrollView {
//                VStack {
//                    Text(paragraph)
//                        .padding(8)
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                        .lineLimit(nil)
//                }
//            }
//            .padding([.top, .leading, .trailing])
//            
//            Spacer()
//            
//            // Audio
//            Button(action: {
//                // Play audio
//                player?.play()
//            }) {
//                Image(systemName: "speaker.fill")
//                    .foregroundColor(.blue)
//            }
//            .padding(.trailing, 8)
//            Spacer()
//            
//            HStack {
//                ForEach(model.solutionsIndexes, id: \.self) { index in
//                    if let word = model.wordsBlocks[index] {
//                        Text(word)
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 8)
//                            .frame(maxHeight: 30)
//                            .background(Color.green)
//                            .foregroundColor(.white)
//                            .cornerRadius(20)
//                            .padding(.trailing, 8)
//                            .onTapGesture {
//                          
//                                var updatedParagraph = paragraph
//                           
//                                let incompleteSpaceIndex = updatedParagraph.range(of: "_________")
//                                guard  let incompleteSpaceIndex = incompleteSpaceIndex else {
//                                    return
//                                }
//                                updatedParagraph = updatedParagraph.replacingCharacters(in: incompleteSpaceIndex, with: word)
//                                let isCorrect = checkSolution(index, updatedParagraph)
//                                if isCorrect ?? false {
//                                    paragraph = updatedParagraph
//                                    // Show a success snackbar
//                                    showSnackbar = true
//                                    snackbarMessage = "Correct!"
//                                    successSoundPlayer?.play()
//                                }
//                                else {
//                                    // Show an error snackbar
//                                    showSnackbar = true
//                                    snackbarMessage = "Incorrect!"
//                                    errorSoundPlayer?.play()
//                                }
//                            }
//                    }
//                }
//            }
//            .padding(.horizontal)
//            
//            Spacer()
//            
//            // Last Row (Image)
//            VStack {
//                Spacer()
//                // Replace this with your image view
//                CachedAsyncImage(url: model.imageUrl, placeholder: Image(systemName: "photo"))
//            }
//            
//        }
//        .padding()   // Add inner padding
//        .background(Color.white)  // Set a background color
//        .cornerRadius(10)         // Add rounded corners
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(Color.gray, lineWidth: 1) // Create a border
//        )
//        .shadow(radius: 3)
//        .onAppear {
//            URLSession.shared.dataTask(with: model.audioUrl) { (data, response, error) in
//                if let error = error {
//                    print("Error fetching audio: \(error)")
//                    return
//                }
//                
//                guard let data = data else {
//                    print("No audio data found")
//                    return
//                }
//                
//                player = try? AVAudioPlayer(data: data)
//                player?.prepareToPlay()
//                player?.volume = 1.0
//                
//            }.resume()
//            updateParagraph()
//            setupAudioPlayers()
//        }
//        .overlay(
//            Group {
//                if showSnackbar {
//                    VStack {
//                        Text(snackbarMessage)
//                            .padding()
//                            .background(Color.black)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                            .transition(.move(edge: .top))
//                            //.withAnimation(.easeOut, {})
//                            .animation(.easeInOut)
//                            .onAppear {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                                    showSnackbar = false
//                                }
//                            }
//                    }
//                    .padding(.top, 32)
//                    .padding(.horizontal)
//                    .zIndex(1)
//                }
//            }
//        )
//    }
//    
//}
//struct GWritingView_Previews: PreviewProvider {
//    static var previews: some View {
//        let completionCard1 = CompletionCardModel(
//            id: "1",
//            wordsBlocks: [0: "She is", 1: "running", 2: "by the", 3: "river.", 4: "She returns home every day after work out. Most of the time she is home by 6 pm."],
//
//            solutionsIndexes: [1, 3],
//            
//            audioUrl: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/eduktok-31554.appspot.com/o/audios%2Funit_1_language_English_lesson_3_id_76856C21-F7DE-4442-AD8C-E91487CD986D.mp3?alt=media&token=5ac0dd7c-6ef2-4ae8-a2e7-25f7ba678d7f")!,
//            
//            
//            
//            imageUrl: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/eduktok-31554.appspot.com/o/images%2Funit_1_language_English_lesson_3_id_76856C21-F7DE-4442-AD8C-E91487CD986D.jpg?alt=media&token=3cb104ef-ab67-4d03-80c9-b5ce0f91e3ff")!
//            
//        )
//        let completionCard2 = CompletionCardModel(
//            id: "2",
//            wordsBlocks: [0: "She is", 1: "running", 2: "by the", 3: "river", 4: ". She returns home every day after work out. Most of the time she is home by 6 pm."],
//
//            solutionsIndexes: [1, 3],
//            
//            audioUrl: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/eduktok-31554.appspot.com/o/audios%2Funit_1_language_English_lesson_3_id_76856C21-F7DE-4442-AD8C-E91487CD986D.mp3?alt=media&token=5ac0dd7c-6ef2-4ae8-a2e7-25f7ba678d7f")!,
//            
//            
//            
//            imageUrl: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/eduktok-31554.appspot.com/o/images%2Funit_1_language_English_lesson_3_id_76856C21-F7DE-4442-AD8C-E91487CD986D.jpg?alt=media&token=3cb104ef-ab67-4d03-80c9-b5ce0f91e3ff")!
//            
//        )
//        let completionCard3 = CompletionCardModel(
//            id: "3",
//            wordsBlocks: [0: "She is", 1: "running", 2: "by the", 3: "river.", 4: "She returns home every day after work out. Most of the time she is home by 6 pm."],
//
//            solutionsIndexes: [1, 3],
//            
//            audioUrl: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/eduktok-31554.appspot.com/o/audios%2Funit_1_language_English_lesson_3_id_76856C21-F7DE-4442-AD8C-E91487CD986D.mp3?alt=media&token=5ac0dd7c-6ef2-4ae8-a2e7-25f7ba678d7f")!,
//            
//            
//            
//            imageUrl: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/eduktok-31554.appspot.com/o/images%2Funit_1_language_English_lesson_3_id_76856C21-F7DE-4442-AD8C-E91487CD986D.jpg?alt=media&token=3cb104ef-ab67-4d03-80c9-b5ce0f91e3ff")!
//            
//        )
//        let model = GWritingModel(lessonNumber: 1, id: "1", type: .GWriting, completionCards: [completionCard1, completionCard2, completionCard3])
//        
//        return GWritingView(model: model, onFinished: {})
//    }
//}


//                    ForEach(Array(wordsBlocks.keys.sorted()), id: \.self) { key in
//                        if solutionsIndexes.contains(key) {
//                            if let word = wordsBlocks[key] {
//                                Text(word)
//                                    .padding(8)
//                                    .background(Color.gray )
//                                    .foregroundColor(.clear)
//                                    .cornerRadius(8)
//                                    .frame(maxWidth: .infinity)
//                                    .multilineTextAlignment(.trailing)
//
//
//                                    .lineLimit(nil)
//                            }
//
//                        } else if let word = wordsBlocks[key] {
//
//                        }
//                    }


//        let completionCard2 = CompletionCardModel(wordsBlocks: [1: "He is", 2: "swimming", 3: "in the", 4: "lake"],
//                                                  solutionsIndexes: [2, 4],
//                                                  audioUrl: URL(string: "https://example.com/audio2.mp3")!,
//                                                  imageUrl: URL(string: "https://example.com/image2.jpg")!)
