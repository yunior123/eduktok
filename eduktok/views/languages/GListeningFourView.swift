//
//  GListeningFourView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 30/3/24.
//

import SwiftUI

struct GListeningFourView: View {
    let model: GListeningFourModel
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
            ForeFourView(models: viewModel.foreModels, viewModel: viewModel)
        }
        .onAppear(){
            viewModel.foreModels = model.foreModels
            viewModel.titleModel = model.foreModels.first // Initialize titleModel
            viewModel.preloadPlayInitialAudio() // Preload audio for the first title
            viewModel.setupAudioPlayers()
            viewModel.onFinished = onFinished
        }
    }
}

struct ForeFourView: View {
    let models: [ListeningModel]
    @ObservedObject var viewModel : GListeningViewModel
    let gridLayout = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout, spacing: 10)
            {
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
