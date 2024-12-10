//
//  ProfileView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//


import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                if let user = $viewModel.user.wrappedValue {
                    AvatarView(user: user, viewModel: viewModel)
                        .padding(20)
                    EmailSection(user: user)
                    UserNameSection(user: user, viewModel: viewModel)
                    SignOutButton()
                    DeleteAccountButton(userId: user.id)
                } else {
                    ProgressView()
                }
            }
            .padding(16)
        }
        .navigationTitle("Settings")
        .onAppear {
            Task{
                viewModel.fetchUser()
            }
        }
    }
}

struct SignOutButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        Button("Sign Out") {
            authViewModel.isSignedIn = false
            Task{
                await signOut()
            }
        }
    }
}

@MainActor func signOut() async {
    do {
        await Task.yield() // Allow UI to update
        try Auth.auth().signOut()
    } catch {
        print("Error in sign out")
    }
}

@MainActor func handleAccountDeletion(userId: String) async throws {
    // 1. Delete user data from Firestore (Db class)
    let db = Db()
    try await db.deleteUser(id: userId)
    try await db.deleteTemplates(userId: userId)
    
    // 2. Delete profile image from Storage (if exists)
    let storageRef = Storage.storage().reference()
    let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
    
    // Attempt to delete, handle non-existence gracefully
    try await profileImageRef.delete()
    
    // 3. Delete user from Firebase Authentication
    let user = FirebaseAuth.Auth.auth().currentUser
    try await user?.delete()
}

struct DeleteAccountButton: View {
    let userId: String
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        Button("Delete Account") {
            authViewModel.isSignedIn = false
            Task{
                await Task.yield() // Allow UI to update
                try await handleAccountDeletion(userId: userId)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.red) // Destructive look
    }
}


struct UserNameSection: View {
    var user: UserModel
    @State private var isEditing = false
    @State private var updatedUsername = ""
    @ObservedObject var viewModel : SettingsViewModel
    
    var body: some View {
        HStack(spacing: 10) {
            Text("Username: ")
                .font(.headline)
            Text(user.username)
                .font(.body)
            
            Button(action: { isEditing = true })  {
                Image(systemName: "pencil")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .sheet(isPresented: $isEditing) {
            EditUsernameView(username: $updatedUsername, isEditing: $isEditing, initialUsername: user.username, viewModel: viewModel)
        }
    }
}

struct EditUsernameView: View {
    @Binding var username: String
    @Binding var isEditing: Bool
    let initialUsername: String
    @State private var showErrorAlert = false
    @ObservedObject var viewModel : SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Username")
                .font(.title2).bold()
            
            TextField("New Username", text: $username)
                .padding()
                .background(.quaternary) // Light background
                .cornerRadius(5)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    username = initialUsername // Reset changes
                    isEditing = false
                }
                
                Button("Save") {
                    if validateUsername(username) {
                        Task{
                            await updateUsername()
                        }
                    } else {
                        showErrorAlert = true
                    }
                }
            }
        }
        .padding()
        .alert("Invalid Username", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text("Please provide a valid username.")
        }
    }
    
    private func validateUsername(_ username: String) -> Bool {
        return !username.isEmpty && username.count >= 5
    }
    
    private func updateUsername() async{
        await viewModel.updateUserName(newName: username)
    }
}


struct EmailSection: View {
    let user: UserModel
    
    var body: some View {
        HStack(spacing: 10) {
            Text("Email: ")
                .font(.headline)
            Text(user.email)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

