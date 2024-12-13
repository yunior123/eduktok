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
    /// Outermost Key: Language (String)
    /// Middle Key: Unit ID (String)
    /// Innermost Key: Lesson ID (String)
    /// Innermost Value: Completion Status (Bool)
    let languageProgress: [String: [String: [String: Bool]]]?
    var learningLanguage: String? = "English"
    let role: String
    let hasLifetimeAccess: Bool
    
    init(id: String, uid: String, email: String, username: String, avatarUrl: String? = nil, languageProgress: [String: [String: [String: Bool]]]? = nil,
         learningLanguage: String? = nil,
         role: String, hasLifetimeAccess: Bool
    ) {
        self.id = id
        self.uid = uid
        self.email = email
        self.username = username
        self.avatarUrl = avatarUrl
        self.languageProgress = languageProgress
        self.learningLanguage = learningLanguage
        self.role = role
        self.hasLifetimeAccess = hasLifetimeAccess
    }
    
    convenience init?(from document: DocumentSnapshot, id: String) {
        guard let data = document.data() else { return nil }
        guard let uid = data["uid"] as? String,
              let username = data["username"] as? String,
              let email = data["email"] as? String else { return nil }
        
        let avatarUrl = data["avatarUrl"] as? String
        let languageProgress = data["languageProgress"]  as? [String: [String: [String: Bool]]]
        let learningLanguage = data["learningLanguage"]  as? String
        guard let role = (data["role"] ?? "user") as? String else { return nil }
        guard let hasLifetimeAccess = (data["hasLifetimeAccess"] ?? false) as? Bool else {
            return nil
        }
        
        self.init(id: id, uid: uid, email: email, username: username, avatarUrl: avatarUrl, languageProgress: languageProgress, learningLanguage: learningLanguage, role: role, hasLifetimeAccess: hasLifetimeAccess)
    }
    
    convenience init?(from json: [String: Any], id: String) {
        guard let uid = json["uid"] as? String,
              let username = json["username"] as? String,
              let email = json["email"] as? String else { return nil }
        
        let avatarUrl = json["avatarUrl"] as? String
        
        let languageProgress = json["languageProgress"]  as? [String: [String: [String: Bool]]]
        let learningLanguage = json["learningLanguage"]  as? String
        guard let role = (json["role"] ?? "user") as? String else { return nil }
        guard let hasLifetimeAccess = (json["hasLifetimeAccess"] ?? false) as? Bool else { return nil }
        
        self.init(id: id, uid: uid, email: email, username: username, avatarUrl: avatarUrl, languageProgress: languageProgress, learningLanguage: learningLanguage, role: role, hasLifetimeAccess:hasLifetimeAccess)
    }
    func copyWith(id: String? = nil,
                  uid: String? = nil,
                  username: String? = nil,
                  email: String? = nil,
                  avatarUrl: String? = nil,
                  languageProgress: [String: [String: [String: Bool]]]? = nil,
                  learningLanguage: String? = nil,
                  role: String? = nil,
                  hasLifetimeAccess: Bool? = nil
    ) -> UserModel {
        
        return UserModel(
            id: id ?? self.id,
            uid: uid ?? self.uid,
            email: email ?? self.email,
            username: username ?? self.username,
            avatarUrl: avatarUrl ?? self.avatarUrl,
            languageProgress: languageProgress ?? self.languageProgress,
            learningLanguage: learningLanguage ?? self.learningLanguage,
            role: role ?? self.role,
            hasLifetimeAccess: hasLifetimeAccess ?? self.hasLifetimeAccess
        )
    }
}
