//
//  SpeechRecognizer.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 5/3/24.
//


import SwiftUI
import Foundation
import Speech
import AVFoundation

actor StreamingSpeechRecognizerViewModel: NSObject, ObservableObject {
    // Published properties for UI
    @MainActor @Published var transcription: String = ""
    @MainActor @Published var isListening: Bool = false
    
    // Speech recognizer instance
    @MainActor private let speechRecognizer: StreamingSpeechRecognizer
    
    @MainActor init(language: Locale) {
        speechRecognizer = StreamingSpeechRecognizer(locale: language)
        super.init()
        
        // Configure result handlers
        speechRecognizer.onResult = { [weak self] partialResult in
            DispatchQueue.main.async {
                self?.transcription = partialResult
            }
        }
        
        speechRecognizer.onFinalResult = { [weak self] finalResult in
            DispatchQueue.main.async {
                self?.transcription = finalResult
            }
        }
        speechRecognizer.onError = { [weak self] error in
            DispatchQueue.main.async {
                print("Error: \(error.localizedDescription)")
                self?.isListening = false
                self?.speechRecognizer.stopRecognition()
            }
        }
    }
    

    @MainActor func stopRecognition() {
        speechRecognizer.stopRecognition()
    }
    
    /// Toggles speech recognition on and off
    @MainActor func toggleRecognition() {
        do {
            if isListening {
                // Stop recognition
                speechRecognizer.stopRecognition()
                isListening = false
            } else {
                // Start recognition
                try speechRecognizer.startRecognition()
                isListening = true
                transcription = ""
            }
        } catch {
            isListening = false
        }
    }
}


// Custom error enum for speech recognition
enum StreamingSpeechError: Error {
    case setupFailed
    case authorizationDenied
}

// MARK: - SFSpeechRecognizerDelegate
extension StreamingSpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle changes in speech recognition availability
        print("Speech recognition availability changed: \(available)")
    }
}

enum RecognizerError: Error {
    case nilRecognizer
    case notAuthorizedToRecognize
    case notPermittedToRecord
    case recognizerIsUnavailable
    
    var message: String {
        switch self {
        case .nilRecognizer: return "Can't initialize speech recognizer"
        case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
        case .notPermittedToRecord: return "Not permitted to record audio"
        case .recognizerIsUnavailable: return "Recognizer is unavailable"
        }
    }
}

class StreamingSpeechRecognizer: NSObject {
    // Speech recognition properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Audio engine properties
    private let audioEngine = AVAudioEngine()
    
    // Callback closures
    var onResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // Initialize with a specific language locale
    init(locale: Locale = Locale.current) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
        
        // Configure speech recognizer
        speechRecognizer?.delegate = self
    }
    
    /// Starts the streaming speech recognition
    func startRecognition() throws {
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Create a recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Ensure the recognition request exists
        guard let recognitionRequest = recognitionRequest else {
            throw StreamingSpeechError.setupFailed
        }
        
        // Configure the recognition request for streaming
        recognitionRequest.shouldReportPartialResults = true
        
        // Start the recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                
                // Call the partial result callback
                self.onResult?(transcription)
                
                // If the result is final, call the final result callback
                if result.isFinal {
                    self.onFinalResult?(transcription)
                }
            }
            
            // Handle any errors
            if let error = error {
                self.onError?(error)
                self.stopRecognition()
            }
        }
        
        // Prepare the audio input
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        try audioEngine.start()
    }
    
    /// Stops the streaming speech recognition
    func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        // Cancel the recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    /// Checks if speech recognition is currently available
    func isAvailable() -> Bool {
        return speechRecognizer?.isAvailable ?? false
    }
}
