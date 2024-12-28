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
            let langCode = viewModel.languageCode!
            let text = model.textDict[langCode]!;
            let audioDict = viewModel.audioUrlDict!
            var urlString = audioDict[langCode]![text]!
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
            var urlString = audioDict[langCode]![text]!

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
    @ObservedObject var viewModel : GListeningViewModel
    
    var body: some View {
        ScrollView {
            LazyHStack {
                ForEach(models) { model in
                    BackCardView(model: model,viewModel: viewModel)
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
    let languageCode: String
    let audioUrlDict: [String: [String:String]]
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
            BackView(models: viewModel.backModels, viewModel: viewModel)
                .foregroundColor(Color.black.opacity(0.5))
            ForeView(models: viewModel.foreModels, viewModel: viewModel)
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
            viewModel.preloadPlayInitialAudio() // Preload audio for the first title
            viewModel.setupAudioPlayers()
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
