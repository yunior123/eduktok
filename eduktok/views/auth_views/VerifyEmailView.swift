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
            VStack {
                Text("Please check your email and click the verification link.")
                    .padding()

                if !isVerificationEmailSent {
                    Button("Resend Verification Email") {
                        authViewModel.sendVerificationEmail()
                        isVerificationEmailSent = true // Update state
                    }
                } else {
                    Text("Verification email sent")
                }
                NavigationLink("Back to Sign Up", destination: SignUpView())
                           .padding()
            }
            .padding()
        }
    }
}


#Preview {
    VerifyEmailView()
}
