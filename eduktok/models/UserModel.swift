//
//  UserModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import Foundation
import Firebase

class UserModel:  Codable, Identifiable {
    let id: String
    let uid: String
    let username: String
    let email: String
    let avatarUrl: String?
    let tags: [String]?
    let tagsScore: [String: Int]?
    /// Outermost Key: Language (String)
    /// Middle Key: Unit ID (String)
    /// Innermost Key: Lesson ID (String)
    /// Innermost Value: Completion Status (Bool)
    let languageProgress: [String: [String: [String: Bool]]]?
    var learningLanguage: String? = "English"
    let role: String
    
    init(id: String, uid: String, email: String, username: String, avatarUrl: String? = nil, tags: [String]? = nil, tagsScore: [String: Int]? = nil, languageProgress: [String: [String: [String: Bool]]]? = nil,
         learningLanguage: String? = nil,
         role: String
    ) {
        self.id = id
        self.uid = uid
        self.email = email
        self.username = username
        self.avatarUrl = avatarUrl
        self.tags = tags
        self.tagsScore = tagsScore
        self.languageProgress = languageProgress
        self.learningLanguage = learningLanguage
        self.role = role
    }
    
    convenience init?(from document: DocumentSnapshot, id: String) {
        guard let data = document.data() else { return nil }
        guard let uid = data["uid"] as? String,
              let username = data["username"] as? String,
              let email = data["email"] as? String else { return nil }
        
        let avatarUrl = data["avatarUrl"] as? String
        let tags = data["tags"] as? [String]
        let tagsScore = data["tagsScore"]  as? [String: Int]
        let languageProgress = data["languageProgress"]  as? [String: [String: [String: Bool]]]
        let learningLanguage = data["learningLanguage"]  as? String
        guard let role = (data["role"] ?? "user") as? String else { return nil }
        
        self.init(id: id, uid: uid, email: email, username: username, avatarUrl: avatarUrl, tags: tags, tagsScore: tagsScore, languageProgress: languageProgress, learningLanguage: learningLanguage, role: role)
    }
    
    convenience init?(from json: [String: Any], id: String) {
        guard let uid = json["uid"] as? String,
              let username = json["username"] as? String,
              let email = json["email"] as? String else { return nil }
        
        let avatarUrl = json["avatarUrl"] as? String
        let tags = json["tags"] as? [String]
        let tagsScore = json["tagsScore"]  as? [String: Int]
        let languageProgress = json["languageProgress"]  as? [String: [String: [String: Bool]]]
        let learningLanguage = json["learningLanguage"]  as? String
        guard let role = (json["role"] ?? "user") as? String else { return nil }
        
        self.init(id: id, uid: uid, email: email, username: username, avatarUrl: avatarUrl, tags: tags, tagsScore: tagsScore, languageProgress: languageProgress, learningLanguage: learningLanguage, role: role)
    }
    func copyWith(id: String? = nil,
                  uid: String? = nil,
                  username: String? = nil,
                  email: String? = nil,
                  avatarUrl: String? = nil,
                  tags: [String]? = nil,
                  tagsScore: [String: Int]? = nil,
                  languageProgress: [String: [String: [String: Bool]]]? = nil,
                  learningLanguage: String? = nil,
                  role: String? = nil
    ) -> UserModel {
        
        return UserModel(
            id: id ?? self.id,
            uid: uid ?? self.uid,
            email: email ?? self.email,
            username: username ?? self.username,
            avatarUrl: avatarUrl ?? self.avatarUrl,
            tags: tags ?? self.tags,
            tagsScore: tagsScore ?? self.tagsScore,
            languageProgress: languageProgress ?? self.languageProgress,
            learningLanguage: learningLanguage ?? self.learningLanguage,
            role: role ?? self.role
        )
    }
    var totalScore: Int {
        tagsScore?.values.reduce(0, +) ?? 0 // Safer total calculation
    }
}
