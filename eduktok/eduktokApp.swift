//
//  eduktokApp.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

// TODO: Add to settings
//    func addMessage(message: String) async throws {
//        guard let email = Auth.auth().currentUser?.email else {
//            return
//        }
//        let collectionRef = firestore.collection("messages")
//        let data: [String: Any] = [
//            "message": message,
//            "userEmail": email
//        ]
//        _ = try await collectionRef.addDocument(data: data)
//    }

//TODO: add notifications, populate cards
//TODO: In the lessons view, the selected circle inside the scrollView should be centered. (it should move to the center?)
//TODO: Remove API keys
//TODO: The transcription should come as a stream
//TODO: Solve <0x14415d400> Gesture: System gesture gate timed out. when switching from one lesson to the other
//TODO: Solve -[SFSpeechRecognitionTask localSpeechRecognitionClient:speechRecordingDidFail:]_block_invoke Ignoring subsequent local speech recording error: Error Domain=kAFAssistantErrorDomain Code=1101 "(null)"
//Received an error while accessing com.apple.speech.localspeechrecognition service: Error Domain=kAFAssistantErrorDomain Code=1101 "(null)"
// TODO: check if audio session active on disappear
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
    -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
}


@main
struct eduktokApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            AuthView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        
    }
}
