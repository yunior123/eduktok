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
