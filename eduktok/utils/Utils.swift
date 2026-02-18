//
//  utils.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//

import Foundation
import CryptoKit
import FirebaseFirestore 
import Firebase
import FirebaseStorage
import SwiftUI

//func createImageFilePath(unit: UnitModel, lessonNumber: Int, id: String) -> String {
//  return "images/unit_\(unit.unitNumber)_lesson_\(lessonNumber)_id_\(id).jpg"
//}
//
//func createAudioPath(unit: UnitModel, lessonNumber: Int, id: String) -> String {
//  return "audios/unit_\(unit.unitNumber)_lesson_\(lessonNumber)_id_\(id).mp3"
//}

//func createImagePath(unitNumber: Int, selectedLanguage: Language) -> String {
//  // Use the raw value (lowercase) of the enum for consistency
//  let languageString = selectedLanguage.rawValue.lowercased()
//  // Include extension in the function for clarity
//  return "images/unit_\(unitNumber)_\(languageString).jpg"
//}



func sha256(_ input: String) -> String { // Applies SHA256 hashing
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}
func randomNonceString(length: Int = 32) -> String {  // Generates a secure nonce
    precondition(length > 0)
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}
// TODO: handle limit

enum APIError: Error {
    case invalidResponse(URLResponse)
    case decodingError
    case unknownError(Error)
}

enum OrignaLTheme {
    static let navy = Color(red: 0.04, green: 0.13, blue: 0.30)
    static let cobalt = Color(red: 0.07, green: 0.29, blue: 0.58)
    static let aurora = Color(red: 0.15, green: 0.60, blue: 0.86)
    static let ice = Color(red: 0.88, green: 0.96, blue: 1.00)
    static let mint = Color(red: 0.47, green: 0.90, blue: 0.92)
    static let rose = Color(red: 0.96, green: 0.44, blue: 0.62)
    static let success = Color(red: 0.43, green: 0.91, blue: 0.62)
    static let warning = Color(red: 1.00, green: 0.81, blue: 0.34)

    static let pageGradient = LinearGradient(
        colors: [navy, cobalt, aurora],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surfaceGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.17),
            Color.white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonGradient = LinearGradient(
        colors: [mint, aurora],
        startPoint: .leading,
        endPoint: .trailing
    )
}

enum UITestLaunchFlags {
    static var isAnyUITestRun: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing") ||
        ProcessInfo.processInfo.arguments.contains("-ui-testing-real")
    }

    static var usesRealDatabaseFlow: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing-real")
    }
}

struct OrignaLBackdrop: View {
    var body: some View {
        ZStack {
            OrignaLTheme.pageGradient
                .ignoresSafeArea()
            Circle()
                .fill(OrignaLTheme.mint.opacity(0.18))
                .frame(width: 260, height: 260)
                .offset(x: 130, y: -290)
                .blur(radius: 15)
            Circle()
                .fill(OrignaLTheme.ice.opacity(0.18))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: 320)
                .blur(radius: 18)
        }
    }
}

struct OrignaLGlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(OrignaLTheme.surfaceGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func orignalGlassCard() -> some View {
        modifier(OrignaLGlassCardModifier())
    }
}

// Firebase Firestore Upload
func uploadUnitDataToFirestore(unit: UnitModel) async throws {
    let collectionRef = Firestore.firestore().collection("units")
    try collectionRef.addDocument(from: unit)
}

func updateUnitInFirestore(unit: UnitModel) async throws {

    let collectionRef = Firestore.firestore().collection("units")
    let documentRef = collectionRef.document(unit.id!)

    do {
        try documentRef.setData(from: unit)
    } catch {
        throw FirestoreError.updateFailure
    }
}

func fetchUnitByDocId(docId: String) async throws -> UnitModel? {
    let collectionRef = Firestore.firestore().collection("units")
    let documentRef = collectionRef.document(docId)

    do {
        let documentSnapshot = try await documentRef.getDocument()
        if let unitModel = UnitModel(from: documentSnapshot) {
            return unitModel
        } else {
            throw FirestoreError.decodeFailure
        }
    } catch {
        throw FirestoreError.fetchFailure
    }
}

//func getLanguageCode(selectedLanguage: String) -> String {
//    switch selectedLanguage {
//    case "German":
//        return "de-DE"
//    case "English":
//        return "en-US"
//    case "French":
//        return "fr-FR"
//    case "Spanish":
//        return "es-ES"
//    case "Italian":
//        return "it-IT"
//    case "Chinese":
//        return "zh-CN"
//    case "Portuguese":
//        return "pt-PT"
//    case "Russian":
//        return "ru-RU"
//    case "Japanese":
//        return "ja-JP"
//    case "Korean":
//        return "ko-KR"
//    default:
//        return "en-US" // Default to English (US)
//    }
//}

func convertToLanguageCode(_ language: String) -> String? {
    let languageCodes = [
        "English": "en",
        "Spanish": "es",
        "French": "fr",
        "German": "de",
        "Italian": "it",
        "Chinese": "zh",
        "Portuguese": "pt",
        "Russian": "ru",
        "Japanese": "ja",
        "Korean": "ko"
    ]
    return languageCodes[language]
}

enum FirestoreError: Error {
    case missingDocumentId
    case updateFailure
    case fetchFailure
    case decodeFailure
}
