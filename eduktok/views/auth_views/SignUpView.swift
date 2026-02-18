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
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 116, height: 116)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(OrignaLTheme.ice.opacity(0.6), lineWidth: 2)
                            )

                        Text("OrignaL")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(OrignaLTheme.ice)

                        Text("Learn the way babies do: hear, see, repeat.")
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(OrignaLTheme.ice.opacity(0.90))
                    }
                    .padding(.top, 14)
                    .accessibilityIdentifier("auth.hero")

                    VStack(spacing: 12) {
                        authTextField(icon: "envelope", placeholder: "Email", text: $authViewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .accessibilityIdentifier("auth.emailField")

                        authSecureField(icon: "lock", placeholder: "Password", text: $authViewModel.password)
                            .accessibilityIdentifier("auth.passwordField")

                        if authMode == .signUp {
                            authSecureField(icon: "lock.shield", placeholder: "Confirm Password", text: $confirmPassword)
                                .accessibilityIdentifier("auth.confirmPasswordField")
                        }

                        Button(authMode == .signIn ? "Sign In" : "Create Account") {
                            if authMode == .signIn {
                                authViewModel.signIn()
                            } else {
                                if authViewModel.password == confirmPassword {
                                    authViewModel.signUp()
                                } else {
                                    authViewModel.errorMessage = "Passwords don't match"
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(OrignaLTheme.buttonGradient)
                        .foregroundStyle(Color.black)
                        .font(.headline)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .accessibilityIdentifier("auth.primaryButton")

                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.white.opacity(0.12))
                                .foregroundStyle(OrignaLTheme.ice)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .accessibilityIdentifier("auth.forgotPasswordButton")

                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote.bold())
                                .foregroundStyle(OrignaLTheme.rose)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("auth.errorText")
                        }

                        HStack(spacing: 10) {
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(OrignaLTheme.ice.opacity(0.85))
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 1)
                        }

                        #warning("fix the apple button, it is always showing sign up")
                        SignInWithAppleButton(authMode == .signIn ? .signIn : .signUp) { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            authViewModel.handleSignInResultApple(result, currentNonce)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        )
                        .accessibilityIdentifier("auth.appleButton")

                        Button(action: { authViewModel.googleSignIn() }) {
                            HStack(spacing: 10) {
                                Image("google")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                Text(authMode == .signIn ? "Sign In with Google" : "Sign Up with Google")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.white)
                            .foregroundStyle(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .accessibilityIdentifier("auth.googleButton")

                        HStack(spacing: 6) {
                            Text(authMode == .signIn ? "New user?" : "Already have an account?")
                                .foregroundStyle(OrignaLTheme.ice.opacity(0.85))
                            Button(authMode == .signIn ? "Sign Up" : "Sign In") {
                                authMode.toggle()
                                authViewModel.errorMessage = nil
                            }
                            .fontWeight(.bold)
                            .foregroundStyle(OrignaLTheme.mint)
                            .accessibilityIdentifier("auth.toggleModeButton")
                        }
                        .font(.subheadline)
                    }
                    .padding(18)
                    .orignalGlassCard()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
        }
        .tint(OrignaLTheme.mint)
    }

    @ViewBuilder
    private func authTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(OrignaLTheme.ice.opacity(0.85))
                .frame(width: 18)
            TextField(placeholder, text: text)
                .foregroundStyle(OrignaLTheme.ice)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(Color.white.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func authSecureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(OrignaLTheme.ice.opacity(0.85))
                .frame(width: 18)
            SecureField(placeholder, text: text)
                .foregroundStyle(OrignaLTheme.ice)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(Color.white.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    SignUpView()
}
