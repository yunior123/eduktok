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
        ScrollView {
            VStack {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                TextField("Email", text: $email)
                Button("Reset Password") {
                    authViewModel.resetPassword(email: email)
                }

                 if let fpErrorMessage = authViewModel.fpErrorMessage {
                     Text(fpErrorMessage)
                         .foregroundColor(.red)
                 }
            }
            .padding()
        }
        .onAppear {
            email = authViewModel.email // Pre-populate from the view model
        }
    }
}

#Preview {
    ForgotPasswordView()
}
