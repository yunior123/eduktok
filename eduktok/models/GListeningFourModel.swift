//
//  GListeningFourModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 30/3/24.
//

import Foundation

struct GListeningFourModel: Identifiable, LessonModel {
    var audioUrlDict: [String : [String : String]]

    static func == (lhs: GListeningFourModel, rhs: GListeningFourModel) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id: String
    var lessonNumber: Int
    var unitNumber: Int  // Added unitNumber property
    var type: GLanguageSkill
    var foreModels: [ListeningModel]
    
    init(id: String,
         lessonNumber: Int,
         unitNumber: Int,  // Added unitNumber parameter
         type: GLanguageSkill,
         foreModels: [ListeningModel],
         audioUrlDict: [String: [String: String]]? = nil
    ) {
        self.id = id
        self.type = type
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
        self.unitNumber = unitNumber  // Assign unitNumber
        self.audioUrlDict = audioUrlDict!
    }
    
    init?(from lessonDict: [String: Any]) {
        guard let id = lessonDict["id"] as? String,
              let lessonNumber = lessonDict["lessonNumber"] as? Int,
              let unitNumber = lessonDict["unitNumber"] as? Int,  // Added unitNumber extraction
              let typeString = lessonDict["type"] as? String,
              let type = GLanguageSkill(rawValue: typeString) else { return nil }
        
        // Extract foreModels
        guard let foreModelsData = lessonDict["foreModels"] as? [[String: Any]] else { return nil }
        let foreModels = foreModelsData.compactMap { ListeningModel(from: $0) }
        
        self.id = id
        self.type = type
        self.foreModels = foreModels
        self.lessonNumber = lessonNumber
        self.unitNumber = unitNumber  // Assign unitNumber
        self.audioUrlDict = lessonDict["audioUrlDict"] as! [String: [String: String]]
    }
    
    enum CodingKeys: CodingKey {
        case id, type, foreModels, lessonNumber, unitNumber, audioUrlDict  // Added unitNumber to CodingKeys
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
        unitNumber = try container.decode(Int.self, forKey: .unitNumber)  // Decode unitNumber
        type = try container.decode(GLanguageSkill.self, forKey: .type)
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
        try container.encode(foreModels, forKey: .foreModels)
        try container.encodeIfPresent(audioUrlDict, forKey: .audioUrlDict)
    }
}
