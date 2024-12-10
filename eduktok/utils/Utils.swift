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

func createImageFilePath(unit: UnitModel, lessonNumber: Int, id: String) -> String {
  return "images/unit_\(unit.unitNumber)_language_\(unit.language)_lesson_\(lessonNumber)_id_\(id).jpg"
}

func createAudioPath(unit: UnitModel, lessonNumber: Int, id: String) -> String {
  return "audios/unit_\(unit.unitNumber)_language_\(unit.language)_lesson_\(lessonNumber)_id_\(id).mp3"
}

func createImagePath(unitNumber: Int, selectedLanguage: Language) -> String {
  // Use the raw value (lowercase) of the enum for consistency
  let languageString = selectedLanguage.rawValue.lowercased()
  // Include extension in the function for clarity
  return "images/unit_\(unitNumber)_\(languageString).jpg"
}



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


enum FirestoreError: Error {
    case missingDocumentId
    case updateFailure
    case fetchFailure
    case decodeFailure
}
