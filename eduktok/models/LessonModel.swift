//
//  GMainModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 4/3/24.
//

import Foundation

enum GLanguageSkill: String, CaseIterable, Codable {
    case GListening = "Listening"
    case GListeningFour = "ListeningFour"
    case GSpeaking = "Speaking"
//    case GWriting = "Writing"
//    case GInterpreting = "Interpreting"
}

protocol LessonModel: Equatable, Hashable, Codable, Decodable {
    var id: String { get }
    var type: GLanguageSkill { get }
    var lessonNumber: Int { get }
    var audioUrlDict: [String: [String: String]] { get }
}
