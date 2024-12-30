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
    var unitNumber: Int  // Added unitNumber property
    var type: GLanguageSkill
    var backModels: [ListeningModel]
    var foreModels: [ListeningModel]
    var audioUrlDict: [String: [String: String]]
    
    init(id: String,
         lessonNumber: Int,
         unitNumber: Int,  // Added unitNumber parameter
         type: GLanguageSkill,
         backModels: [ListeningModel],
         foreModels: [ListeningModel],
         audioUrlDict: [String: [String: String]] = [:]
    ) {
        self.id = id
        self.type = type
        self.backModels = backModels
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
        self.unitNumber = unitNumber  // Assign unitNumber
        self.audioUrlDict = audioUrlDict
    }
    
    init?(from lessonDict: [String: Any]) {
        guard let id = lessonDict["id"] as? String,
              let lessonNumber = lessonDict["lessonNumber"] as? Int,
              let unitNumber = lessonDict["unitNumber"] as? Int,  // Added unitNumber extraction
              let typeString = lessonDict["type"] as? String,
              let type = GLanguageSkill(rawValue: typeString) else { return nil }
        
        // Extract backModels
        guard let backModelsData = lessonDict["backModels"] as? [[String: Any]] else { return nil }
        let backModels = backModelsData.compactMap { ListeningModel(from: $0) }
        
        // Extract foreModels
        guard let foreModelsData = lessonDict["foreModels"] as? [[String: Any]] else { return nil }
        let foreModels = foreModelsData.compactMap { ListeningModel(from: $0) }
        
        let audioUrlDictData = lessonDict["audioUrlDict"] as? [String: [String: String]]
        
        self.id = id
        self.type = type
        self.audioUrlDict = audioUrlDictData!
        self.backModels = backModels
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
        self.unitNumber = unitNumber  // Assign unitNumber
    }
    
    enum CodingKeys: CodingKey {
        case id, type, backModels, foreModels, lessonNumber, unitNumber, audioUrlDict  // Added unitNumber to CodingKeys
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
        unitNumber = try container.decode(Int.self, forKey: .unitNumber)  // Decode unitNumber
        type = try container.decode(GLanguageSkill.self, forKey: .type)
        backModels = try container.decode([ListeningModel].self, forKey: .backModels)
        foreModels = try container.decode([ListeningModel].self, forKey: .foreModels)
        audioUrlDict = try container
            .decodeIfPresent(
                [String: [String: String]].self,
                forKey: .audioUrlDict
            )!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lessonNumber, forKey: .lessonNumber)
        try container.encode(unitNumber, forKey: .unitNumber)  // Encode unitNumber
        try container.encode(type, forKey: .type)
        try container.encode(backModels, forKey: .backModels)
        try container.encode(foreModels, forKey: .foreModels)
        try container.encodeIfPresent(audioUrlDict, forKey: .audioUrlDict)
    }
}
