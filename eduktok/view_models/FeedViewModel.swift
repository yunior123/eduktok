//
//  FeedViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 13/3/24.
//

import SwiftUI
import Firebase

class FeedViewModel: ObservableObject {
    let db = Db()
    @Published var templates: [TemplateModel] = []
    private var templatesListener: ListenerRegistration?
    
    func fetchTemplates(userModel: UserModel) {
        let id = userModel.id
        
        templatesListener = db.templatesListener(userId: id).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Failed to listen for changes: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            
            let docs = snapshot.documents.compactMap { document in
                return try? document.data(as: TemplateModel.self)
            }
            
            self?.templates = docs
        }
    }
    
    func disposeListeners() {
        templatesListener?.remove()
        templatesListener = nil
    }
    
    deinit {
        disposeListeners()
    }
}
