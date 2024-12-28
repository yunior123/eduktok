//
//  File.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 29/4/24.
//

import SwiftUI

//class GWritingViewModel: ObservableObject {
//    @Published var models: [CompletionCardModel] = []
//    var onFinished: () -> Void = {}
//    
//    func markCardCompleted(id: String) {
//        if let index = models.firstIndex(where: { $0.id == id }) {
//            models[index].completed = true
//            
//            // Check for overall completion
//            if models.allSatisfy({ $0.completed }) {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Auto-hide error
//                    self.onFinished()
//                }
//            }
//        }
//    }
//}
