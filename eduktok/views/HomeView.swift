//
//  ListView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import SwiftUI
import Speech
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State var isLoading: Bool = true
    var body: some View {
        VStack{
            Spacer()
            if let userModel = $viewModel.userModel.wrappedValue {
                TabView {
                    LanguageView(userModel: userModel)
                        .tabItem {
                            Label("Languages", systemImage: "globe")
                        }
                        .tag(0)
                        .id(0)
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        if userModel.role == "admin" {
                            // Show admin-specific controls
                            UnitCreationView()
                                .tabItem {
                                    Label("Unit Creation", systemImage: "square.and.pencil")
                                }
                                .tag(1)
                                .id(1)
                            LessonCreationView()
                                .tabItem {
                                    Label("Lesson Creation", systemImage: "book")
                                }
                                .tag(2)
                                .id(2)
                        }
                    }
                    
//                    MemoryCardsView(userModel: userModel)
//                        .tabItem {
//                            Label("MemoryCards", systemImage: "checklist")
//                        }
//                        .tag(3)
//                        .id(3)
                    SettingsView().tabItem {
                        Label("Settings", systemImage: "gear")
                    }.tag(6).id(6)
                }
            }
            
        }
        .navigationTitle("Eduktok")
        .onAppear {
            Task {
                try await viewModel.setupUser()
                await requestPermissions()
            }
        }
    }
    
}

func requestPermissions() async{
    SFSpeechRecognizer.requestAuthorization { status in
        switch status {
        case .authorized:
            print("Speech recognition authorized.")
        case .denied:
            print("Speech recognition denied.")
            return
        case .restricted:
            print("Speech recognition restricted.")
            return
        case .notDetermined:
            print("Speech recognition not determined.")
            return
        @unknown default:
            print("Unknown speech recognition status.")
            return
        }
    }
    do {
        guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
            print("Microphone access denied.")
            return
        }
        print("Microphone access granted")
    }
}

#Preview {
    HomeView()
}
