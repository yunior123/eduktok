//
//  SettingsViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//
import SwiftUI
import Firebase
import FirebaseStorage

class SettingsViewModel: ObservableObject {
    @Published var user: UserModel? = nil
    let db = Db()
    private var userListener: ListenerRegistration?
    
    func fetchUser() {
        guard let email = Auth.auth().currentUser?.email else {
            return
        }
        userListener = db.userListener(email: email).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Failed to listen for changes: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            
            self?.user = snapshot.documents.compactMap { document in
                guard let userModel = UserModel(from: document,id: document.documentID) else {
                    print("Error creating UnitModel from document")
                    return nil }
                return userModel
            }.first
        }
    }
    
    func updateUserName(newName: String) async {
        guard let user = user else {
            return
        }
        do{
            try await db.updateUser(user: user.copyWith(username: newName))
        }
        catch {
            print("Error updating user name")
        }
    }
    
    func uploadProfilePicture(image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return } // Ensure data conversion
        guard let usermodel = self.user else{
            return
        }
        let userId = usermodel.id
        let storageRef = Storage.storage().reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        do {
            let _ = try await profileImageRef.putDataAsync(imageData)
            
            // 2. Get Download URL
            let downloadURL = try await profileImageRef.downloadURL()
            
            // 2. Update Firestore
            let db = Db()
            try await db.updateUser(user: usermodel.copyWith(avatarUrl: downloadURL.absoluteString))
            
            
        } catch {
            throw error // Re-throw the error for handling
        }
    }
    
    func disposeListeners() {
        userListener?.remove()
        userListener = nil
    }
    
    deinit {
        disposeListeners()
    }
}
