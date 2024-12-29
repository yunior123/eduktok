//
//  ListView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import SwiftUI
import Speech
import AVFoundation
import Foundation
import StoreKit
import OSLog
typealias SKTransaction = StoreKit.Transaction


private let logger = Logger(subsystem: "Eduktok", category: "HomeView")


struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State var isLoading: Bool = true
    @State private var isPro = false
    
    var body: some View {
        VStack {
            Spacer()
            if let userModel = $viewModel.userModel.wrappedValue {
                TabView {
                    LanguageView(userModel: userModel, isPro: (isPro || userModel.hasLifetimeAccess))
                        .tabItem {
                            Label("Languages", systemImage: "globe")
                        }
                        .tag(0)
                        .id(0)
                    
                    if (!(isPro || userModel.hasLifetimeAccess))
                    {
                        StoreKitProViewMP(userDocId: userModel.id)
                            .tabItem {
                                Label("Store", systemImage: "crown.fill")
                            }
                            .tag(1)
                            .id(1)
                        
                    }
                    SettingsView().tabItem {
                        Label("Settings", systemImage: "gear")
                    }.tag(2).id(2)
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
        .onInAppPurchaseStart { product in
            print("onInAppPurchaseStart called")
            print(product)
        }
        .currentEntitlementTask(for: Products.lifetime) { taskState in
            if let verification = taskState.transaction,
               let transaction = try? verification.payloadValue {
                print("Transaction: \(transaction)")
                print(
                    "AppAccountToken: \(String(describing: transaction.appAccountToken))"
                )
                isPro = transaction.revocationDate == nil
            } else {
                isPro = false
            }
        }
    }
}

func requestPermissions() async{
    SFSpeechRecognizer.requestAuthorization { status in
        switch status {
        case .authorized: break
            //print("Speech recognition authorized.")
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
        //print("Microphone access granted")
    }
}

#Preview {
    HomeView()
}


