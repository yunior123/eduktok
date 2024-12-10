//
//  UnitModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 16/3/24.
//

import SwiftUI
import Firebase

struct UnitModel: Codable, Identifiable, Equatable, Hashable {
    static func == (lhs: UnitModel, rhs: UnitModel) -> Bool {
        // Logic to determine equality between two UnitModel instances
        return lhs.id == rhs.id //  Compare based on the ID
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    let id: String?
    let unitName: String
    let unitNumber: Int
    let title: String
    let imageUrl: URL
    var lessons: [any LessonModel] = []
    let language: String
    
    init(id: String, unitName: String, unitNumber: Int, title: String, imageUrl: URL, lessons: [any LessonModel] = [], language: String) {
        self.id = id
        self.unitName = unitName
        self.unitNumber = unitNumber
        self.title = title
        self.imageUrl = imageUrl
        self.lessons = lessons
        self.language = language
    }
    // Initializer from a database snapshot (Example using Firebase)
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        guard let unitName = data["unitName"] as? String else { return nil }
        guard let unitNumber = data["unitNumber"] as? Int else { return nil }
        guard let title = data["title"] as? String else { return nil }
        guard let imageUrlString = data["imageUrl"] as? String,
              let imageUrl = URL(string: imageUrlString) else { return nil }
        guard let language = data["language"] as? String else { return nil }
        
        guard let lessonsData = data["lessons"] as? [[String: Any]] else { return nil }
        
        self.id = document.documentID
        self.unitName = unitName
        self.unitNumber = unitNumber
        self.title = title
        self.imageUrl = imageUrl
        self.language = language
        
        self.lessons = lessonsData.compactMap { lessonDict in
            return createLesson(from: lessonDict)
        }
        
    }
    // Initializer for Codable
    enum CodingKeys: CodingKey { // Define coding keys to match your property names
        case id, unitName, unitNumber, title, imageUrl, lessons, language
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        unitName = try container.decode(String.self, forKey: .unitName)
        unitNumber = try container.decode(Int.self, forKey: .unitNumber)
        title = try container.decode(String.self, forKey: .title)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
        language = try container.decode(String.self, forKey: .language)
        var lessonsContainer = try container.nestedUnkeyedContainer(forKey: .lessons)
        var lessons: [any LessonModel] = []
        
        struct LessonDictData: Decodable {
            let type: String
            let id: String
        }
        
        while !lessonsContainer.isAtEnd {
            let lessonDict = try lessonsContainer.decode(LessonDictData.self)
            
            guard let skill = GLanguageSkill(rawValue: lessonDict.type) else { continue }
            var lesson: (any LessonModel)?
            
            switch skill {
            case .GListening:
                lesson = try lessonsContainer.decode(GListeningModel.self)
            case .GListeningFour:
                lesson = try lessonsContainer.decode(GListeningFourModel.self)
            case .GSpeaking:
                lesson = try lessonsContainer.decode(GSpeakingModel.self)
            case .GWriting:
                lesson = try lessonsContainer.decode(GWritingModel.self)
            case .GInterpreting:
                lesson = try lessonsContainer.decode(GInterpretingModel.self)
            }
            
            if let lesson = lesson {
                lessons.append(lesson)
            }
        }
        
        self.lessons = lessons
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(unitName, forKey: .unitName)
        try container.encode(unitNumber, forKey: .unitNumber)
        try container.encode(title, forKey: .title)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(language, forKey: .language)
        var lessonsContainer = container.nestedUnkeyedContainer(forKey: .lessons)
        for lesson in lessons {
            switch lesson.type {
            case .GListening:
                try lessonsContainer.encode(lesson as! GListeningModel)
            case .GSpeaking:
                try lessonsContainer.encode(lesson as! GSpeakingModel)
            case .GWriting:
                try lessonsContainer.encode(lesson as! GWritingModel)
            case .GInterpreting:
                try lessonsContainer.encode(lesson as! GInterpretingModel)
            case .GListeningFour:
                try lessonsContainer.encode(lesson as! GListeningFourModel)
            }
        }
    }
    func copyWith(
        id: String? = nil,
        unitName: String? = nil,
        unitNumber: Int? = nil,
        title: String? = nil,
        imageUrl: URL? = nil,
        lessons: [any LessonModel]? = nil,
        language: String? = nil
    ) -> UnitModel {

        return UnitModel(
            id: id ?? self.id!,
            unitName: unitName ?? self.unitName,
            unitNumber: unitNumber ?? self.unitNumber,
            title: title ?? self.title,
            imageUrl: imageUrl ?? self.imageUrl,
            lessons: lessons ?? self.lessons,
            language: language ?? self.language
        )
    }
    // Helper function to create specific lesson types
    private func createLesson(from lessonDict: [String: Any]) -> (any LessonModel)? {
        guard let lessonType = lessonDict["type"] as? String,
              let skill = GLanguageSkill(rawValue: lessonType) else { return nil }
        
        switch skill {
        case .GListening:
            return GListeningModel(from: lessonDict)
        case .GSpeaking:
            return GSpeakingModel(from: lessonDict)
        case .GWriting:
            return GWritingModel(from: lessonDict)
        case .GInterpreting:
            return GInterpretingModel(from: lessonDict)
        case .GListeningFour:
            return GListeningFourModel(from: lessonDict)
        }
    }
}
