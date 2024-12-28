//
//  LanguageViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 16/3/24.
//


import SwiftUI
import Firebase

class LanguageViewModel: ObservableObject {
    let db = Db()
    @Published var units: [UnitModel] = []
    private var unitsListener: ListenerRegistration?
    
    func fetchUnits() {
        unitsListener = db.unitsListener().addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Failed to listen for changes: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            var docs: [UnitModel] = []
            docs = snapshot.documents.compactMap { document in
                
                guard let unitModel = UnitModel(from: document) else {
                    print("Error creating UnitModel from document")
                    return nil
                }
                return unitModel
            }
            
            self?.units = docs
        }
    }
    
    func disposeListeners() {
        unitsListener?.remove()
        unitsListener = nil
    }
    
    deinit {
        disposeListeners()
    }
}
