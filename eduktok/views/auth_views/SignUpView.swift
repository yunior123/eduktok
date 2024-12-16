//
//  SignUpView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 29/2/24.
//

import SwiftUI
import Firebase
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

enum AuthMode: CaseIterable{
    case signIn
    case signUp
    
    mutating func toggle() {
        switch self {
        case .signIn: self = .signUp
        case .signUp: self = .signIn
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Access the view model
    @State private var currentNonce: String? // For security with Sign in with Apple
    @State private var authMode: AuthMode = .signUp // Start with sign-up mode
    @State private var confirmPassword = "" // For confirm password field
    
    var body: some View {
        NavigationStack {
            ScrollView  {
                VStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                    TextField("Email", text: $authViewModel.email) // Bind to view model's property
                        .frame(width: 250, height: 50)
                        .textContentType(.emailAddress) // Important
                        .keyboardType(.emailAddress) // Optional, but recommended
                    SecureField("Password", text: $authViewModel.password)
                        .frame(width: 250, height: 50)
                        .textContentType(.newPassword) // Important
                        .textContentType(.oneTimeCode)  // Helps password autofill
                    if authMode == .signUp { // Conditionally show confirm password
                        SecureField("Confirm Password", text: $confirmPassword)
                            .frame(width: 250, height: 50)
                            .textContentType(.newPassword)
                            .textContentType(.oneTimeCode)
                    }
                    Button(authMode == .signIn ? "Sign In" : "Sign Up") {
                        if authMode == .signIn {
                            authViewModel.signIn()
                        } else {
                            // Validate confirm password
                            let password = authViewModel.password
                            if password == confirmPassword {
                                authViewModel.signUp()
                            } else {
                                authViewModel.errorMessage = "Passwords don't match"
                            }
                        }
                    }
                    .frame(width: 250, height: 50)
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .frame(width: 250, height: 50)
                            .foregroundColor(.blue)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    SignInWithAppleButton(authMode == .signIn ? .signIn : .signUp) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        authViewModel.handleSignInResultApple(result,currentNonce)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(width: 250, height: 50)
                    Button(action: { authViewModel.googleSignIn() }) {
                        HStack {
                            Image("google") // Assuming you've named the image 'GoogleLogo' in assets
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20) // Adjust sizing as needed
                            
                            Text(authMode == .signIn ? "Sign In with Google" : "Sign Up with Google")
                                .font(.system(.body, design: .default).weight(.semibold))
                        }
                    }
                    .frame(width: 250, height: 50)
                    .background(Color.white) // Google buttons are often white
                    .foregroundColor(.black)  // Black foreground text
                    .clipShape(RoundedRectangle(cornerRadius: 5)) // Slightly rounded corners
                    .overlay( // Add a subtle border
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                    )
                    
                    HStack {
                        Text(authMode == .signIn ? "New User?" : "Already have an account?")
                        Button(authMode == .signIn ? "Sign Up" : "Sign In") {
                            authMode.toggle()
                        }
                    }
                }
                
                
            }
            .padding()
        }
        
    }
    
}

#Preview {
    SignUpView()
}
