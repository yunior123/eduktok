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
            if (viewModel.shouldTransition) || (viewModel.isCardMatched ?? false) && (model.text == viewModel.titleModel?.text) {
                HStack {
                    Text(model.text)
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
                if (viewModel.isCardMatched ?? false) && (model.text == viewModel.titleModel?.text) {
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
                    // Prepare the audio session
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession
                        .setCategory(
                            .playback,
                            mode: .spokenAudio,
                            options: .duckOthers
                        )
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("❌ Failed to set up playback audio session")
                    print("❌ \(error.localizedDescription)")
                }
            }
            
            
            guard let url = model.audioUrl else { return }
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

struct BackCardView: View {
    let model: ListeningModel
    
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        VStack {
            HStack {
                Text(model.text)
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
            guard let url = model.audioUrl else { return }
            
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
    
    var body: some View {
        ScrollView {
            LazyHStack {
                ForEach(models) { model in
                    BackCardView(model: model)
                        .frame(width: 200, height: 200)
                }
            }
            
        }
        .padding()
        
    }
}

struct ForeView: View {
    let models: [ListeningModel]
    @ObservedObject var viewModel : GListeningViewModel
    var body: some View {
        ScrollView { // Horizontal scrolling
            LazyHStack {
                ForEach(models) { model in
                    ForeCardView(model: model, viewModel: viewModel)
                        .frame(width: 200, height: 200)
                        .onTapGesture {
                            viewModel.checkMatch(selectedModel: model)
                        }
                }
            }
        }
        .padding()
    }
}

struct GListeningView: View {
    let model: GListeningModel
    let onFinished: () -> Void
    @StateObject private var viewModel = GListeningViewModel()
    
    var body: some View {
        VStack(alignment:.center) {
            HStack (alignment:.center){
                Text(viewModel.titleModel?.text ?? "")
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
            BackView(models: viewModel.backModels)
                .foregroundColor(Color.black.opacity(0.5))
            ForeView(models: viewModel.foreModels, viewModel: viewModel)
        }
        .onAppear(){
            viewModel.backModels = model.backModels
            viewModel.foreModels = model.foreModels
            viewModel.titleModel = model.foreModels.first // Initialize titleModel
            viewModel.preloadPlayInitialAudio() // Preload audio for the first title
            viewModel.setupAudioPlayers()
            viewModel.onFinished = onFinished
        }
    }
}
