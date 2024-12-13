//
//  TemplateViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Combine
import Firebase

class HomeViewModel: ObservableObject {
    
    private let db = Db()
    @Published var userModel: UserModel?
    private var userListener: ListenerRegistration?
    
    @MainActor func setupUser() async throws {
        let user = Auth.auth().currentUser
        guard let user = user else {
            return
        }
        guard let email = user.email else {
            return
        }
        createUserListener()
        let existingUser = try await db.findUser(email: email)
        
        if existingUser == nil {
            let randomId = UUID().uuidString
            let uid = user.uid
            guard  let email = user.email else{
                return
            }
            let username = user.displayName ?? email.components(separatedBy: "@").first!
            let avatarUrl = user.photoURL?.absoluteString
            
            let userModel = UserModel(
                id: randomId,
                uid: uid,
                email: email,
                username: username,
                avatarUrl: avatarUrl,
                role: "user",
                hasLifetimeAccess: false
            )
            
            let docId = try await db.createUser(userModel)
            try await db.updateUser(user: userModel.copyWith(id: docId))
        }
    }
    
    func createUserListener() {
        guard let email = Auth.auth().currentUser?.email else {
            return
        }
        userListener = db.userListener(email: email).addSnapshotListener {  [weak self] snapshot, error in
            if let error = error {
                print("Failed to listen for changes: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            
            self?.userModel = snapshot.documents.compactMap { document in
                guard let userModel = UserModel(from: document,id: document.documentID) else {
                    print("Error creating UnitModel from document")
                    return nil }
                return userModel
            }.first
            
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
