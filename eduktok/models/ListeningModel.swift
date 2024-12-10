//
//  ListeningModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import Foundation

struct ListeningModel: Identifiable, Codable {
    var id: String
    var text: String
    var audioUrl: URL?
    var imageUrl: URL?
    var imageData: Data? // Temporary storage for image data
    var audioData: Data? // Temporary storage for audio data
    
    enum CodingKeys: CodingKey {
        case id, text, audioUrl, imageUrl, imageData, audioData
    }

    init(id: String, text: String, audioUrl: URL?, imageUrl: URL?, imageData: Data? = nil, audioData: Data? = nil) {
        self.id = id
        self.text = text
        self.audioUrl = audioUrl
        self.imageUrl = imageUrl
        self.imageData = imageData
        self.audioData = audioData
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        audioUrl = try container.decode(URL.self, forKey: .audioUrl)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(audioUrl, forKey: .audioUrl)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
}
