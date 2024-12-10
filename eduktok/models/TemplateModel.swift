//
//  template_model.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import Foundation
import Firebase

struct TemplateModel: Equatable, Codable, Identifiable {
    let id: String
    let tags: [String]
    let title: String
    let description: String?
    let url: URL?
    let imageUrl: URL?
    let nextDate: Timestamp
    let intervals: [Int]
    let createdBy: String
    let dateCreated: Timestamp
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        guard let id = document.documentID as String? else { return nil } // Treat ID as string
        guard let title = data["title"] as? String else { return nil }
        guard let nextDate = data["nextDate"] as? Timestamp else { return nil }
        guard let dateCreated = data["dateCreated"] as? Timestamp else { return nil }
        guard let createdBy = data["createdBy"] as? String else { return nil }
        guard let tags = data["tags"] as? [String] else { return nil }
        
        let intervals = data["intervals"] as? [Int] ?? [2, 3, 7, 15, 30, 60, 120, 240, 480, 960]
        let description = data["description"] as? String
        let urlString = data["url"] as? String
        let imageUrlString = data["imageUrl"] as? String
        let url = urlString != nil ? URL(string: urlString!) : nil
        let imageUrl = imageUrlString != nil ? URL(string: imageUrlString!) : nil
        
        self.id = id
        self.tags = tags
        self.title = title
        self.description = description
        self.url = url
        self.imageUrl = imageUrl // Assign imageUrl
        self.nextDate = nextDate
        self.intervals = intervals
        self.createdBy = createdBy
        self.dateCreated = dateCreated
    }
    
    init(
        id: String,
        tags: [String],
        title: String,
        description: String?,
        url: URL?,
        imageUrl: URL?, // Add imageUrl parameter
        nextDate: Timestamp,
        intervals: [Int],
        createdBy: String,
        dateCreated: Timestamp) {
            self.id = id
            self.tags = tags
            self.title = title
            self.description = description
            self.url = url
            self.imageUrl = imageUrl
            self.nextDate = nextDate
            self.intervals = intervals
            self.createdBy = createdBy
            self.dateCreated = dateCreated
            
            
        }
    func copyWith(
        id: String? = nil,
        tags: [String]? = nil,
        title: String? = nil,
        description: String? = nil,
        url: URL? = nil,
        imageUrl: URL? = nil, 
        nextDate: Timestamp? = nil,
        intervals: [Int]? = nil,
        createdBy: String? = nil,
        dateCreated: Timestamp? = nil) -> TemplateModel {
            
            let newId = id ?? self.id
            let newTags = tags ?? self.tags
            let newTitle = title ?? self.title
            let newDescription = description ?? self.description
            let newUrl = url ?? self.url
            let newImageUrl = imageUrl ?? self.imageUrl
            let newNextDate =  nextDate ?? self.nextDate
            let newIntervals = intervals ?? self.intervals
            let newCreatedBy = createdBy ?? self.createdBy
            let newDateCreated = dateCreated ?? self.dateCreated
            
            return TemplateModel(id: newId,
                                 tags: newTags,
                                 title: newTitle,
                                 description: newDescription,
                                 url: newUrl,
                                 imageUrl: newImageUrl,
                                 nextDate: newNextDate,
                                 intervals: newIntervals,
                                 createdBy: newCreatedBy,
                                 dateCreated: newDateCreated)
        }
}
