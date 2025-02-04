//
//  LanguageLearningViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import SwiftUI
import AVKit
import Foundation
import AVFoundation

class GListeningViewModel: ObservableObject {
    @Published var backModels: [ListeningModel] = []
    @Published var foreModels: [ListeningModel] = []
    @Published var titleModel: ListeningModel?
    @Published private(set) var isCardMatched: Bool?
    @Published private(set) var currentModelIndex = 0
    @Published private(set) var shouldTransition = false // For signaling completion
    @Published private(set) var tappedCardId: String?
    
    private var titlePlayer: AVAudioPlayer?
    private var successSoundPlayer: AVAudioPlayer?
    private var errorSoundPlayer: AVAudioPlayer?
    @Published var languageCode: String?
    @Published var audioUrlDict: [String: [String:String]]?
    
    var onFinished: () -> Void = {}
    
    func setupAudioPlayers() {
        if let audioData = NSDataAsset(name: "success")?.data {
            do {
                successSoundPlayer = try AVAudioPlayer(data: audioData)
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }
        else {
            print("Sound success file not found")
        }
        if let audioData = NSDataAsset(name: "error")?.data {
            do {
                errorSoundPlayer = try AVAudioPlayer(data: audioData)
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }
        else {
            print("Sound error file not found")
        }
    }
    
    
    func preloadPlayInitialAudio() {
        guard let titleModel = titleModel else { return }
        let text = titleModel.textDict[languageCode!];
        let url = audioUrlDict![languageCode!]![text!]!;
        guard let url = URL(string: url) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                print("Error fetching audio: \(error)")
                return
            }
            
            guard let data = data else {
                print("No audio data found")
                return
            }
            self?.titlePlayer = try? AVAudioPlayer(data: data)
            self?.titlePlayer?.prepareToPlay()
            self?.titlePlayer?.volume = 1.0
            self?.titlePlayer?.play()
        }.resume()
    }
    
    func checkMatch(selectedModel: ListeningModel) {
        tappedCardId = selectedModel.id
        guard let titleModel = titleModel else { return }
        let titleText = titleModel.textDict[languageCode!];
        let selectedText = selectedModel.textDict[languageCode!];
        if selectedText == titleText{
            isCardMatched = true
            playSuccessSound() // Play success sound
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Auto-hide error
                self.advanceToNextTitle()
            }
        } else {
            isCardMatched = false // Show the error overlay
            playErrorSound() // Play the error sound
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Auto-hide error
                self.isCardMatched = nil
                self.tappedCardId = nil
            }
        }
    }
    
    func playSuccessSound() {
        successSoundPlayer?.play()
    }
    
    func playErrorSound() {
        errorSoundPlayer?.play()
    }
    
    func advanceToNextTitle() {
        currentModelIndex += 1
        if currentModelIndex < foreModels.count {
            titleModel = foreModels[currentModelIndex]
            preloadPlayInitialAudio()
            isCardMatched = false
            tappedCardId = nil
        } else {
            isCardMatched = nil
            tappedCardId = nil
            shouldTransition = true
            onFinished()
        }
    }
    
    func playAudio() {
        titlePlayer?.play()
    }
    
    func cleanupAudioPlayers() {
        titlePlayer?.stop()
        titlePlayer = nil
        successSoundPlayer?.stop()
        successSoundPlayer = nil
        errorSoundPlayer?.stop()
        errorSoundPlayer = nil
    }

}
