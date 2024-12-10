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
    var type: GLanguageSkill
    var models: [SpeakingModel]
    
    init(id: String, lessonNumber: Int, type: GLanguageSkill, models: [SpeakingModel]) {
        self.id = id
        self.type = type
        self.models = models
        self.lessonNumber = lessonNumber
    }
    
    init?(from lessonDict: [String: Any]) {
        guard let id = lessonDict["id"] as? String,
              let lessonNumber = lessonDict["lessonNumber"] as? Int,
              let typeString = lessonDict["type"] as? String,
              let type = GLanguageSkill(rawValue: typeString) else { return nil }
        
        guard let modelsData = lessonDict["models"] as? [[String: Any]] else { return nil }
        let models = modelsData.compactMap { SpeakingModel(from: $0) }
        
        self.id = id
        self.type = type
        self.models = models
        self.lessonNumber = lessonNumber
    }
    
    enum CodingKeys: CodingKey { // Define coding keys
        case id, type, models, lessonNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
        type = try container.decode(GLanguageSkill.self, forKey: .type)
        models = try container.decode([SpeakingModel].self, forKey: .models) // Decode models array
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lessonNumber, forKey: .lessonNumber)
        try container.encode(type, forKey: .type)
        try container.encode(models, forKey: .models) // Encode models array
    }
}

struct SpeakingModel: Identifiable, Codable {
    var id: String
    let text: String
    var audioUrl: URL?
    var imageUrl: URL?
    var completed = false
    var imageData: Data? // Temporary storage for image data
    var audioData: Data? // Temporary storage for audio data
    
    enum CodingKeys: CodingKey {
        case id, text, audioUrl, imageUrl, completed, imageData, audioData
    }

    init(id: String, text: String, audioUrl: URL?, imageUrl: URL?, completed: Bool = false, imageData: Data? = nil, audioData: Data? = nil) {
        self.id = id
        self.text = text
        self.audioUrl = audioUrl
        self.imageUrl = imageUrl
        self.completed = completed
        self.imageData = imageData
        self.audioData = audioData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        audioUrl = try container.decode(URL.self, forKey: .audioUrl)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
    }
    
    init?(from dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let text = dict["text"] as? String,
              let audioUrlString = dict["audioUrl"] as? String,
              let audioUrl = URL(string: audioUrlString),
              let imageUrlString = dict["imageUrl"] as? String,
              let imageUrl = URL(string: imageUrlString) else { return nil }
        
        self.id = id
        self.text = text
        self.audioUrl = audioUrl
        self.imageUrl = imageUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(audioUrl, forKey: .audioUrl)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
}
