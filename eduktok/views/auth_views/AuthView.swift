//
//  ContentView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import SwiftUI
import Firebase

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            if authViewModel.isSignedIn {
                if let user = Auth.auth().currentUser, user.isEmailVerified {
                    HomeView()
                        .environmentObject(authViewModel)
                        .edgesIgnoringSafeArea(.top)
                } else {
                    VerifyEmailView()
                        .environmentObject(authViewModel)
                }
            } else {
                SignUpView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    AuthView()
}
