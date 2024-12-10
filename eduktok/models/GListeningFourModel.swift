//
//  GListeningFourModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 30/3/24.
//

import Foundation

struct GListeningFourModel: Identifiable, LessonModel {

    static func == (lhs: GListeningFourModel, rhs: GListeningFourModel) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id: String
    var lessonNumber: Int
    var type: GLanguageSkill
    var foreModels: [ListeningModel]
    
    init(id: String, lessonNumber: Int, type: GLanguageSkill, foreModels: [ListeningModel]) {
        self.id = id
        self.type = type
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
    }
    
    init?(from lessonDict: [String: Any]) {
        guard let id = lessonDict["id"] as? String,
              let lessonNumber = lessonDict["lessonNumber"] as? Int,
              let typeString = lessonDict["type"] as? String,
              let type = GLanguageSkill(rawValue: typeString) else { return nil }
        
        // Extract foreModels
        guard let foreModelsData = lessonDict["foreModels"] as? [[String: Any]] else { return nil }
        let foreModels = foreModelsData.compactMap { ListeningModel(from: $0) }
        
        self.id = id
        self.type = type
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
    }
    
    enum CodingKeys: CodingKey {
        case id, type, foreModels, lessonNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
        type = try container.decode(GLanguageSkill.self, forKey: .type)
        foreModels = try container.decode([ListeningModel].self, forKey: .foreModels)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lessonNumber, forKey: .lessonNumber)
        try container.encode(type, forKey: .type)
        try container.encode(foreModels, forKey: .foreModels)
    }
    
}
