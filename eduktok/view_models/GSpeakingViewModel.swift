//
//  GSpeakingViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 13/3/24.
//

import SwiftUI

class GSpeakingViewModel: ObservableObject {
    @Published var models: [SpeakingModel] = []
    var onFinished: () -> Void = {}
    
    func markCardCompleted(id: String) {
        if let index = models.firstIndex(where: { $0.id == id }) {
            models[index].completed = true
            
            // Check for overall completion
            if models.allSatisfy({ $0.completed }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Auto-hide error
                    self.onFinished()
                }
            }
        }
    }
}
