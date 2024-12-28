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
    let title: [String: String]
    let imageUrl: URL
    var lessons: [any LessonModel] = []
    
    init(id: String, unitName: String, unitNumber: Int, title: [String: String], imageUrl: URL, lessons: [any LessonModel] = []) {
        self.id = id
        self.unitName = unitName
        self.unitNumber = unitNumber
        self.title = title
        self.imageUrl = imageUrl
        self.lessons = lessons
    }
    // Initializer from a database snapshot (Example using Firebase)
    init?(from document: DocumentSnapshot) {
        // Debug Step 1: Check if we can get the document data
        guard let data = document.data() else {
            print("❌ Failed to get document data")
            return nil
        }
        
        //print("📄 Raw document data: \(data)")
        
        // Debug Step 2: Check unitNumber parsing
        //print("🔍 Attempting to parse unitNumber. Raw value: \(String(describing: data["unitNumber"]))")
        guard let unitNumber = data["unitNumber"] as? Int else {
            print("❌ Failed to parse unitNumber. Type received: \(type(of: data["unitNumber"]))")
            return nil
        }
        //print("✅ Successfully parsed unitNumber: \(unitNumber)")
        
        // Debug Step 3: Check title parsing
        //print("🔍 Attempting to parse title. Raw value: \(String(describing: data["title"]))")
        guard let title = data["title"] as? [String: String] else {
            print("❌ Failed to parse title. Type received: \(type(of: data["title"]))")
            return nil
        }
        //print("✅ Successfully parsed title: \(title)")
        
        // Debug Step 4: Check imageUrl parsing
        //print("🔍 Attempting to parse imageUrl. Raw value: \(String(describing: data["imageUrl"]))")
        guard let imageUrlString = data["imageUrl"] as? String else {
            print("❌ Failed to parse imageUrl string. Type received: \(type(of: data["imageUrl"]))")
            return nil
        }
        guard let imageUrl = URL(string: imageUrlString) else {
            print("❌ Failed to create URL from string: \(imageUrlString)")
            return nil
        }
        //print("✅ Successfully parsed imageUrl: \(imageUrl)")
        
        // Debug Step 5: Check lessons parsing
        //print("🔍 Attempting to parse lessons. Raw value: \(String(describing: data["lessons"]))")
        let lessonsData = (data["lessons"] as? [[String: Any]]) ?? []
        //print("✅ Using lessons data. Count: \(lessonsData.count)")
        
        // If we get here, all parsing succeeded - set the properties
        self.id = document.documentID
        self.unitName = "Unit \(unitNumber)"
        self.unitNumber = unitNumber
        self.title = title
        self.imageUrl = imageUrl
        
        // Debug Step 6: Parse individual lessons
        self.lessons = []
        for (index, lessonDict) in lessonsData.enumerated() {
            //print("🔍 Attempting to parse lesson \(index + 1)")
            if let lesson = createLesson(from: lessonDict) {
                self.lessons.append(lesson)
                //print("✅ Successfully parsed lesson \(index + 1)")
            } else {
                print("⚠️ Failed to parse lesson \(index + 1). Raw data: \(lessonDict)")
            }
        }
        
        //print("✅ Successfully initialized unit with \(self.lessons.count) lessons")
    }
    // Initializer for Codable
    enum CodingKeys: CodingKey { // Define coding keys to match your property names
        case id, unitName, unitNumber, title, imageUrl, lessons
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        unitName = try container.decode(String.self, forKey: .unitName)
        unitNumber = try container.decode(Int.self, forKey: .unitNumber)
        title = try container.decode([String: String].self, forKey: .title)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
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
        var lessonsContainer = container.nestedUnkeyedContainer(forKey: .lessons)
        for lesson in lessons {
            switch lesson.type {
            case .GListening:
                try lessonsContainer.encode(lesson as! GListeningModel)
            case .GSpeaking:
                try lessonsContainer.encode(lesson as! GSpeakingModel)
            case .GListeningFour:
                try lessonsContainer.encode(lesson as! GListeningFourModel)
            }
        }
    }
    func copyWith(
        id: String? = nil,
        unitName: String? = nil,
        unitNumber: Int? = nil,
        title: [String: String]? = nil,
        imageUrl: URL? = nil,
        lessons: [any LessonModel]? = nil
    ) -> UnitModel {

        return UnitModel(
            id: id ?? self.id!,
            unitName: unitName ?? self.unitName,
            unitNumber: unitNumber ?? self.unitNumber,
            title: title ?? self.title,
            imageUrl: imageUrl ?? self.imageUrl,
            lessons: lessons ?? self.lessons
        )
    }
    // Helper function to create specific lesson types
    private func createLesson(from lessonDict: [String: Any]) -> (any LessonModel)? {
        guard let lessonType = lessonDict["type"] as? String,
              let skill = GLanguageSkill(rawValue: lessonType) else { return nil }
        
        switch skill {
        case .GListening:
            let model = GListeningModel(from: lessonDict)
            return model
        case .GSpeaking:
            return GSpeakingModel(from: lessonDict)
        case .GListeningFour:
            return GListeningFourModel(from: lessonDict)
        }
    }
}
