//
//  GSpeakingModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import Foundation

struct GSpeakingModel: Identifiable, LessonModel {
    
    static func == (lhs: GSpeakingModel, rhs: GSpeakingModel) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id: String
    var lessonNumber: Int
    var unitNumber: Int  // Added unitNumber property
    var type: GLanguageSkill
    var models: [SpeakingModel]
    var audioUrlDict: [String: [String: String]]
    
    init(id: String,
         lessonNumber: Int,
         unitNumber: Int,  // Added unitNumber parameter
         type: GLanguageSkill,
         models: [SpeakingModel],
         audioUrlDict: [String: [String: String]] = [:]
    ) {
        self.id = id
        self.type = type
        self.models = models
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
        
        guard let modelsData = lessonDict["models"] as? [[String: Any]] else { return nil }
        let models = modelsData.compactMap { SpeakingModel(from: $0) }
        let audioUrlDictData = lessonDict["audioUrlDict"] as? [String: [String: String]]
        
        self.id = id
        self.type = type
        self.audioUrlDict = audioUrlDictData!
        self.models = models
        self.lessonNumber = lessonNumber
        self.unitNumber = unitNumber  // Assign unitNumber
    }
    
    enum CodingKeys: CodingKey {
        case id, type, models, lessonNumber, unitNumber, audioUrlDict  // Added unitNumber to CodingKeys
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
        unitNumber = try container.decode(Int.self, forKey: .unitNumber)  // Decode unitNumber
        type = try container.decode(GLanguageSkill.self, forKey: .type)
        models = try container.decode([SpeakingModel].self, forKey: .models)
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
        try container.encode(models, forKey: .models)
        try container.encodeIfPresent(audioUrlDict, forKey: .audioUrlDict)
    }
}

struct SpeakingModel: Identifiable, Codable {
    var id: String
    var textDict: [String:String]
    var imageUrl: URL?
    var completed = false
    var imageData: Data? // Temporary storage for image data
    var audioData: Data? // Temporary storage for audio data
    
    enum CodingKeys: CodingKey {
        case id, textDict, audioUrl, imageUrl, completed, imageData, audioData
    }

    init(id: String, textDict: [String:String], audioUrl: URL?, imageUrl: URL?, completed: Bool = false, imageData: Data? = nil, audioData: Data? = nil) {
        self.id = id
        self.textDict = textDict
        self.imageUrl = imageUrl
        self.completed = completed
        self.imageData = imageData
        self.audioData = audioData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        textDict = try container.decode([String:String].self, forKey: .textDict)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
    }
    
    init?(from dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let textDict = dict["text"] as? [String:String],
              let imageUrlString = dict["imageUrl"] as? String,
              let imageUrl = URL(string: imageUrlString) else { return nil }
        
        self.id = id
        self.textDict = textDict
        self.imageUrl = imageUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(textDict, forKey: .textDict)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
}
