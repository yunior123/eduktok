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
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: String?
    let unitName: String
    let unitNumber: Int
    let title: [String: String]
    let imageUrl: URL
    
    init(id: String, unitName: String, unitNumber: Int, title: [String: String], imageUrl: URL) {
        self.id = id
        self.unitName = unitName
        self.unitNumber = unitNumber
        self.title = title
        self.imageUrl = imageUrl
    }
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else {
            print("❌ Failed to get document data")
            return nil
        }
        
        guard let unitNumber = data["unitNumber"] as? Int else {
            print("❌ Failed to parse unitNumber. Type received: \(type(of: data["unitNumber"]))")
            return nil
        }
        
        guard let title = data["title"] as? [String: String] else {
            print("❌ Failed to parse title. Type received: \(type(of: data["title"]))")
            return nil
        }
        
        guard let imageUrlString = data["imageUrl"] as? String else {
            print("❌ Failed to parse imageUrl string. Type received: \(type(of: data["imageUrl"]))")
            return nil
        }
        guard let imageUrl = URL(string: imageUrlString) else {
            print("❌ Failed to create URL from string: \(imageUrlString)")
            return nil
        }
        
        self.id = document.documentID
        self.unitName = "Unit \(unitNumber)"
        self.unitNumber = unitNumber
        self.title = title
        self.imageUrl = imageUrl
    }
    
    enum CodingKeys: CodingKey {
        case id, unitName, unitNumber, title, imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        unitName = try container.decode(String.self, forKey: .unitName)
        unitNumber = try container.decode(Int.self, forKey: .unitNumber)
        title = try container.decode([String: String].self, forKey: .title)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(unitName, forKey: .unitName)
        try container.encode(unitNumber, forKey: .unitNumber)
        try container.encode(title, forKey: .title)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
    
    func copyWith(
        id: String? = nil,
        unitName: String? = nil,
        unitNumber: Int? = nil,
        title: [String: String]? = nil,
        imageUrl: URL? = nil
    ) -> UnitModel {
        return UnitModel(
            id: id ?? self.id!,
            unitName: unitName ?? self.unitName,
            unitNumber: unitNumber ?? self.unitNumber,
            title: title ?? self.title,
            imageUrl: imageUrl ?? self.imageUrl
        )
    }
}
