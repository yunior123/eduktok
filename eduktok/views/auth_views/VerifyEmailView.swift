//
//  VerifyEmailView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 29/2/24.
//

import SwiftUI
import Firebase

struct VerifyEmailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isVerificationEmailSent = false

    var body: some View {
        NavigationStack {
            ZStack {
                OrignaLBackdrop()
                VStack(spacing: 14) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(OrignaLTheme.mint)

                    Text("Verify Your Email")
                        .font(.title2.bold())
                        .foregroundStyle(OrignaLTheme.ice)
                    Text("Please check your inbox and click the verification link.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(OrignaLTheme.ice.opacity(0.88))

                    if !isVerificationEmailSent {
                        Button("Resend Verification Email") {
                            authViewModel.sendVerificationEmail()
                            isVerificationEmailSent = true
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(OrignaLTheme.buttonGradient)
                        .foregroundStyle(Color.black)
                        .font(.headline)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityIdentifier("auth.verify.resendButton")
                    } else {
                        Text("Verification email sent")
                            .foregroundStyle(OrignaLTheme.success)
                            .font(.subheadline.bold())
                            .accessibilityIdentifier("auth.verify.sentLabel")
                    }

                    NavigationLink("Back to Sign Up", destination: SignUpView())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OrignaLTheme.ice)
                        .padding(.top, 4)
                        .accessibilityIdentifier("auth.verify.backToSignUp")
                }
                .padding(20)
                .orignalGlassCard()
                .padding(.horizontal, 18)
            }
        }
    }
}


#Preview {
    VerifyEmailView()
}
