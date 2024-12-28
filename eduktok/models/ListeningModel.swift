//
//  ListeningModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import Foundation

struct ListeningModel: Identifiable, Codable {
    var id: String
    var textDict: [String:String]
    var imageUrl: URL?
    var imageData: Data? // Temporary storage for image data
    var audioData: Data? // Temporary storage for audio data
    
    enum CodingKeys: CodingKey {
        case id, textDict, imageUrl, imageData, audioData
    }

    init(id: String, textDict: [String:String], audioUrl: URL?, imageUrl: URL?, imageData: Data? = nil, audioData: Data? = nil) {
        self.id = id
        self.textDict = textDict
        self.imageUrl = imageUrl
        self.imageData = imageData
        self.audioData = audioData
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        textDict = try container.decode([String:String].self, forKey: .textDict)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(textDict, forKey: .textDict)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
}
