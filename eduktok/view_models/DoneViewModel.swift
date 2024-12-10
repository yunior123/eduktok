//
//  DoneViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//

import SwiftUI
import Firebase

class DoneViewModel: ObservableObject {
    @Published var doneTemplates: [TemplateModel] = []
    let db = Db()
    private var doneListener: ListenerRegistration?
    
    func fetchDoneTemplates(userModel: UserModel) {
        let id = userModel.id
        doneListener = db.doneListener(userId: id) .addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Failed to listen for changes: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            
            let templates = snapshot.documents.compactMap { document in
                return try? document.data(as: TemplateModel.self)
            }
            self?.doneTemplates = templates
        }
    }
    
    func disposeListeners() {
        doneListener?.remove()
        doneListener = nil
        
    }
    
    deinit {
        disposeListeners()
    }
}
