//
//  GListeningModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import Foundation

struct GListeningModel: Identifiable, LessonModel {

    static func == (lhs: GListeningModel, rhs: GListeningModel) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id: String
    var lessonNumber: Int
    var type: GLanguageSkill
    var backModels: [ListeningModel]
    var foreModels: [ListeningModel]
    
    init(id: String, lessonNumber: Int, type: GLanguageSkill, backModels: [ListeningModel], foreModels: [ListeningModel]) {
        self.id = id
        self.type = type
        self.backModels = backModels
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
    }
    
    init?(from lessonDict: [String: Any]) {
        guard let id = lessonDict["id"] as? String,
              let lessonNumber = lessonDict["lessonNumber"] as? Int,
              let typeString = lessonDict["type"] as? String,
              let type = GLanguageSkill(rawValue: typeString) else { return nil }
        
        // Extract backModels
        guard let backModelsData = lessonDict["backModels"] as? [[String: Any]] else { return nil }
        let backModels = backModelsData.compactMap { ListeningModel(from: $0) }
        
        // Extract foreModels
        guard let foreModelsData = lessonDict["foreModels"] as? [[String: Any]] else { return nil }
        let foreModels = foreModelsData.compactMap { ListeningModel(from: $0) }
        
        self.id = id
        self.type = type
        self.backModels = backModels
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
    }
    
    enum CodingKeys: CodingKey {
        case id, type, backModels, foreModels, lessonNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
        type = try container.decode(GLanguageSkill.self, forKey: .type)
        backModels = try container.decode([ListeningModel].self, forKey: .backModels)
        foreModels = try container.decode([ListeningModel].self, forKey: .foreModels)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lessonNumber, forKey: .lessonNumber)
        try container.encode(type, forKey: .type)
        try container.encode(backModels, forKey: .backModels)
        try container.encode(foreModels, forKey: .foreModels)
    }
    
}
