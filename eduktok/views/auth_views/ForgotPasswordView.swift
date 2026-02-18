//
//  ForgotPasswordView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 29/2/24.
//

import SwiftUI
import Firebase

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""

    var body: some View {
        ZStack {
            OrignaLBackdrop()
            ScrollView {
                VStack(spacing: 14) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 104, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .padding(.top, 12)

                    Text("Reset Password")
                        .font(.title2.bold())
                        .foregroundStyle(OrignaLTheme.ice)
                        .accessibilityIdentifier("auth.forgot.title")

                    Text("Enter your email and we will send a reset link.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(OrignaLTheme.ice.opacity(0.88))

                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundStyle(OrignaLTheme.ice.opacity(0.85))
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                            .foregroundStyle(OrignaLTheme.ice)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("auth.forgot.emailField")

                    Button("Reset Password") {
                        authViewModel.resetPassword(email: email)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(OrignaLTheme.buttonGradient)
                    .foregroundStyle(Color.black)
                    .font(.headline)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .accessibilityIdentifier("auth.forgot.resetButton")

                    if let fpErrorMessage = authViewModel.fpErrorMessage {
                        Text(fpErrorMessage)
                            .foregroundStyle(OrignaLTheme.ice)
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("auth.forgot.message")
                    }
                }
                .padding(18)
                .orignalGlassCard()
                .padding(.horizontal, 18)
            }
        }
        .onAppear {
            email = authViewModel.email // Pre-populate from the view model
        }
    }
}

#Preview {
    ForgotPasswordView()
}
