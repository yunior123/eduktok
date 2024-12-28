////
////  GInterpretingModel.swift
////  eduktok
////
////  Created by Yunior Rodriguez Osorio on 4/3/24.
////
//
//import Foundation
//
//struct GInterpretingModel: Identifiable, LessonModel {
//    var audioUrlDict: [String : [String : String]]
//
//    static func == (lhs: GInterpretingModel, rhs: GInterpretingModel) -> Bool {
//        return lhs.id == rhs.id
//    }
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//    var id: String
//    var lessonNumber: Int
//    
//    var type: GLanguageSkill
//    
//    init?(from lessonDict: [String: Any]) {
//        guard let id = lessonDict["id"] as? String,
//              let lessonNumber = lessonDict["lessonNumber"] as? Int,
//              let typeString = lessonDict["type"] as? String,
//              let type = GLanguageSkill(rawValue: typeString) else { return nil }
//        
//        
//        self.id = id
//        self.type = type
//        self.lessonNumber = lessonNumber
//        
//    }
//}
