////
////  GWritingModel.swift
////  eduktok
////
////  Created by Yunior Rodriguez Osorio on 4/3/24.
////
//
//import Foundation
//
//struct GWritingModel: Identifiable, LessonModel, Encodable {
//    var audioUrlDict: [String : [String : String]]
//
//    var lessonNumber: Int
//    var id: String
//    var type: GLanguageSkill
//    let completionCards: [CompletionCardModel]
//    
//    init(lessonNumber: Int, id: String, type: GLanguageSkill, completionCards: [CompletionCardModel]) {
//        self.lessonNumber = lessonNumber
//        self.id = id
//        self.type = type
//        self.completionCards = completionCards
//    }
//    
//    enum CodingKeys: String, CodingKey {
//        case id, type, lessonNumber, completionCards
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        
//        try container.encode(id, forKey: .id)
//        try container.encode(type.rawValue, forKey: .type)
//        try container.encode(lessonNumber, forKey: .lessonNumber)
//        try container.encode(completionCards, forKey: .completionCards)
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        self.id = try container.decode(String.self, forKey: .id)
//        self.type = try container.decode(GLanguageSkill.self, forKey: .type)
//        self.lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
//        self.completionCards = try container.decode([CompletionCardModel].self, forKey: .completionCards)
//    }
//    
//    init?(from lessonDict: [String: Any]) {
//        guard let id = lessonDict["id"] as? String,
//              let lessonNumber = lessonDict["lessonNumber"] as? Int,
//              let typeString = lessonDict["type"] as? String,
//              let type = GLanguageSkill(rawValue: typeString) else { return nil }
//        guard let completionCardsData = lessonDict["completionCards"] as? [[String: Any]] else { return nil }
//        let completionCards = completionCardsData.compactMap { CompletionCardModel(from: $0) }
//        self.id = id
//        self.type = type
//        self.lessonNumber = lessonNumber
//        //TODO: finish
//        self.completionCards = completionCards
//    }
//}
//
//struct CompletionCardModel: Identifiable, Decodable, Hashable, Encodable {
//    var id: String
//    let wordsBlocks: [Int: String]
//    let solutionsIndexes: [Int]
//    let audioUrl: URL
//    let imageUrl: URL
//    
//    var completed = false
//    
//    // other properties...
//    init(id: String, wordsBlocks: [Int: String], solutionsIndexes: [Int], audioUrl: URL, imageUrl: URL) {
//        self.id = id
//        self.wordsBlocks = wordsBlocks
//        self.solutionsIndexes = solutionsIndexes
//        self.audioUrl = audioUrl
//        self.imageUrl = imageUrl
//    }
//    
//    init?(from dict: [String: Any]) {
//        guard let id = dict["id"] as? String,
//              let audioUrlString = dict["audioUrl"] as? String,
//              let audioUrl = URL(string: audioUrlString),
//              let imageUrlString = dict["imageUrl"] as? String,
//              let imageUrl = URL(string: imageUrlString),
//              let wordsBlocksDict = dict["wordsBlocks"] as? [String: String],
//              let solutionsIndexesArray = dict["solutionsIndexes"] as? [Int] else { return nil }
//
//        // Convert wordsBlocksDict to [Int: String]
//        var wordsBlocks = [Int: String]()
//        for (key, value) in wordsBlocksDict {
//            if let index = Int(key) {
//                wordsBlocks[index] = value
//            }
//        }
//
//        self.id = id
//        self.audioUrl = audioUrl
//        self.imageUrl = imageUrl
//        self.wordsBlocks = wordsBlocks
//        self.solutionsIndexes = solutionsIndexesArray
//    }
//    
//    enum CodingKeys: String, CodingKey {
//        case id, wordsBlocks, solutionsIndexes, audioUrl, imageUrl
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        
//        try container.encode(id, forKey: .id)
//        try container.encode(wordsBlocks, forKey: .wordsBlocks)
//        try container.encode(solutionsIndexes, forKey: .solutionsIndexes)
//        try container.encode(audioUrl, forKey: .audioUrl)
//        try container.encode(imageUrl, forKey: .imageUrl)
//        // Encode other properties if needed
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        self.id = try container.decode(String.self, forKey: .id)
//        self.wordsBlocks = try container.decode([Int: String].self, forKey: .wordsBlocks)
//        self.solutionsIndexes = try container.decode([Int].self, forKey: .solutionsIndexes)
//        self.audioUrl = try container.decode(URL.self, forKey: .audioUrl)
//        self.imageUrl = try container.decode(URL.self, forKey: .imageUrl)
//        // Decode other properties if needed
//    }
//}
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
