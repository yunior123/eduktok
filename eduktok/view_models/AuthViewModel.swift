//
//  AuthViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//

import Foundation
import SwiftUI
import Firebase
import GoogleSignInSwift
import GoogleSignIn
import AuthenticationServices

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String? = nil
    @Published var fpErrorMessage: String? = nil
    
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.isSignedIn = true
            }
        }
    }
    
    func resetPassword() {
        if !email.isEmpty {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    self.fpErrorMessage = error.localizedDescription
                } else {
                    self.fpErrorMessage = "Password reset email sent. Please check your inbox."
                }
            }
        } else {
            self.fpErrorMessage = "Please enter your email"
        }
    }
    
    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                // Send verification email
                self.sendVerificationEmail()
            }
        }
    }
    
    func sendVerificationEmail() {
        if let user = Auth.auth().currentUser {
            user.sendEmailVerification { error in
                if let error = error {
                    // Handle error (You might want to display feedback to the user)
                    print("Error sending verification email: \(error)")
                } else {
                    // Inform the user that the verification email has been sent
                    print("Verification email sent.")
                }
            }
        }
    }
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        addAuthListener()
    }
    
    private func addAuthListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            self?.isSignedIn = user != nil
        }
    }
    
    private func removeAuthListener() {
        if let authStateListenerHandle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }
    
    func handleSignInResultApple(_ result: Result<ASAuthorization, Error>,_ currentNonce: String?){
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                func formatName(from components: PersonNameComponents?) -> String {
                    let formatter = PersonNameComponentsFormatter()
                    return components != nil ? formatter.string(from: components!) : "Name Unavailable"
                }
                
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data")
                    return
                }
                
                // Initialize a Firebase credential.
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                
                // Sign in with Firebase.
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    // User is signed in to Firebase with Apple.
                    self.isSignedIn = true
                }
            }
            
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    func googleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController
        else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController){ [unowned self] result, error in
            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase Sign In Error: \(error.localizedDescription)")
                    return
                }
                print("Google Sign In Successful")
                self.isSignedIn = true
            }
        }
        
        
    }
    
    deinit { // Clean up the listener when the ViewModel is destroyed
        removeAuthListener()
    }
}
