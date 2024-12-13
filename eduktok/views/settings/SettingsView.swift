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
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let user = $viewModel.user.wrappedValue {
                            // Profile Header
                            ProfileHeaderView(user: user, viewModel: viewModel)
                            
                            // Settings Sections
                            SettingsSectionView {
                                AccountInfoSection(user: user, viewModel: viewModel)
                                ContactSection(user: user)
                                
                                // Sign Out Section
                                SignOutSection(showSignOutConfirmation: $showSignOutConfirmation)
                                
                                // Danger Zone
                                DangerZoneSection(
                                    userId: user.id,
                                    showDeleteConfirmation: $showDeleteConfirmation
                                )
                            }
                        } else {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding()
                }
                
                // Floating Help Button
                HelpFloatingButton()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    viewModel.fetchUser()
                }
            }
            .confirmationDialog(
                "Sign out of Eduktok",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// Profile Header with Avatar and Basic Info
struct ProfileHeaderView: View {
    let user: UserModel
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        HStack {
            AvatarView(user: user, viewModel: viewModel)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Reusable Settings Section Container
struct SettingsSectionView<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 10) {
            content()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Account Information Section
struct AccountInfoSection: View {
    let user: UserModel
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showEditUsername = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: { showEditUsername = true }) {
                SettingsRowView(
                    icon: "person.circle",
                    title: "Username",
                    value: user.username
                )
            }
            .sheet(isPresented: $showEditUsername) {
                EditUsernameView(
                    username: .constant(user.username),
                    isEditing: $showEditUsername,
                    initialUsername: user.username,
                    viewModel: viewModel
                )
            }
            
            Divider()
            
            SettingsRowView(
                icon: "envelope",
                title: "Email",
                value: user.email
            )
        }
        .padding()
    }
}

// Reusable Settings Row
struct SettingsRowView: View {
    let icon: String
    let title: String
    let value: String
    
    init(
        icon: String,
        title: String,
        value: String
    ) {
        self.icon = icon
        self.title = title
        self.value = value
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
    }
}

// Contact Section
struct ContactSection: View {
    let user: UserModel
    @State private var showContactSupport = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: { showContactSupport = true }) {
                SettingsRowView(
                    icon: "message",
                    title: "Contact Support",
                    value: "Get help or send feedback"
                )
            }
            .sheet(isPresented: $showContactSupport) {
                ContactUsPopup(
                    isShowingPopup: $showContactSupport,
                    user: user
                )
            }
        }
        .padding()
    }
}

struct SignOutSection: View {
    @Binding var showSignOutConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: { showSignOutConfirmation = true }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("Sign Out")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

// Danger Zone Section
struct DangerZoneSection: View {
    let userId: String
    @Binding var showDeleteConfirmation: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.red)
            
            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
            }
            .confirmationDialog(
                "Are you sure?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        authViewModel.isSignedIn = false
                        try? await handleAccountDeletion(userId: userId)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding()
    }
}


// Help Floating Button
struct HelpFloatingButton: View {
    @State private var showHelpSheet = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showHelpSheet = true }) {
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showHelpSheet) {
            HelpView()
        }
    }
}

// Simple Help View
struct HelpView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Frequently Asked Questions")) {
                    HelpRowView(
                        title: "How to change username",
                        description: "Tap on the username in the profile section to edit."
                    )
                    HelpRowView(
                        title: "Contact Support",
                        description: "Use the 'Contact Support' option to send us a message."
                    )
                    HelpRowView(
                        title: "Account Deletion",
                        description: "Permanently delete your account from the Danger Zone section."
                    )
                }
            }
            .navigationTitle("Help")
        }
    }
}

// Help Row View
struct HelpRowView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
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
    
    // 2. Delete profile image from Storage (if exists)
    let storageRef = Storage.storage().reference()
    let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
    
    // Attempt to delete, handle non-existence gracefully
    try await profileImageRef.delete()
    
    // 3. Delete user from Firebase Authentication
    let user = FirebaseAuth.Auth.auth().currentUser
    try await user?.delete()
}

// Contact Us Popup View
struct ContactUsPopup: View {
    @Binding var isShowingPopup: Bool
    let user: UserModel
    @State private var messageText = ""
    @State private var showConfirmation = false
    @State private var showErrorAlert = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("We'd love to hear from you!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Share your feedback, report an issue, or ask a question.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)

                TextField("Write your message here...", text: $messageText, axis: .vertical)
                    .lineLimit(6, reservesSpace: true)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(10)

                Spacer()
            }
            .padding()
            .navigationBarTitle("Contact Support", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isShowingPopup = false
                },
                trailing: Button("Send") {
                    Task {
                        await sendMessage()
                    }
                }
                .disabled(messageText.isEmpty)
            )
            .alert("Message Sent", isPresented: $showConfirmation) {
                Button("OK") {
                    isShowingPopup = false
                }
            } message: {
                Text("Your message has been sent successfully.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text("Failed to send message. Please try again.")
            }
        }
    }

    private func sendMessage() async {
        do {
            let db = Db()
            let messageData: [String: Any] = [
                "userId": user.id,
                "email": user.email,
                "message": messageText,
                "timestamp": Timestamp()
            ]
            try await db.firestore
                .collection("messages")
                .addDocument(data: messageData)
            showConfirmation = true
        } catch {
            print("Failed to send message: \(error.localizedDescription)")
            showErrorAlert = true
        }
    }
}

struct EditUsernameView: View {
    @Binding var username: String
    @Binding var isEditing: Bool
    let initialUsername: String
    @State private var updatedUsername = ""
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false // Add success alert state
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Update Username")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose a unique username between 5-20 characters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("New Username", text: $updatedUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.vertical)
            }
            .padding()
            .navigationBarTitle("Edit Username", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isEditing = false
                },
                trailing: Button("Save") {
                    if validateUsername(updatedUsername) {
                        Task {
                            await updateUsername()
                        }
                    } else {
                        showErrorAlert = true
                    }
                }
            )
            .alert("Invalid Username", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text("Username must be 5-20 characters long and cannot be empty.")
            }
            .alert("Success", isPresented: $showSuccessAlert) { // Success alert
                Button("OK") {
                    isEditing = false
                }
            } message: {
                Text("Your username has been successfully updated.")
            }
            .onAppear {
                updatedUsername = initialUsername
            }
        }
    }

    private func validateUsername(_ username: String) -> Bool {
        return !username.isEmpty && username.count >= 5 && username.count <= 20
    }

    private func updateUsername() async {
        do {
            try await viewModel.updateUserName(newName: updatedUsername)
            showSuccessAlert = true // Show success alert after updating
        } catch {
            print("Failed to update username: \(error.localizedDescription)")
            showErrorAlert = true
        }
    }
}
