//
//  db.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import Foundation
import FirebaseFirestore
import Firebase
import Combine

class Db {
    let firestore = Firestore.firestore()
    
    func fetchLessonsForUnit(unitNumber: Int) async throws -> [DocumentSnapshot] {
        let lessonsSnapshot = try await firestore.collection("lessonsNew")
            .whereField("unitNumber", isEqualTo: unitNumber)
            .getDocuments()
        
        return lessonsSnapshot.documents
    }
    
    func findUser(email: String) async throws -> UserModel? {
        let usersRef = firestore.collection("users")
        let query = usersRef.whereField("email", isEqualTo: email).limit(to: 1)
        let querySnapshot = try await query.getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            guard let userModel = UserModel(from: document,id: document.documentID) else {
                print("Error creating UnitModel from document")
                return nil }
            return userModel
        }.first
    }
    
    func createUser(_ user: UserModel) async throws -> String {
        let usersRef = firestore.collection("users")
        let documentRef = try usersRef.addDocument(from: user)
        return documentRef.documentID
    }
    
    func deleteUser(id: String) async throws {
        let docRef = firestore.collection("users").document(id)
        try await docRef.delete()
    }
    
    func fsTaskUpdateOneDocWithId(collection: String, docId: String, model: [String: Any]) async throws {
        let docRef = firestore.collection(collection).document(docId)
        try await docRef.updateData(model)
    }
    
    func updateUser(user: UserModel) async throws {
        guard let encodedData = try? JSONEncoder().encode(user) else {
            print("Error encoding user") // Update Error Message
            return
        }
        guard let model = try? JSONSerialization.jsonObject(with: encodedData) as? [String: Any] else {
            print("Error converting user to dictionary") // Update Error Message
            return
        }
        try await fsTaskUpdateOneDocWithId(collection: "users", docId: user.id, model: model)
    }
    
    func unitsListener() -> Query {
        return firestore.collection("unitsNew")
    }
    
    func userListener(email: String) -> Query {
        return firestore.collection("users")
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
    }
    
//    func removeLessonFromUnit(unitId: String, lessonId: String, unit: UnitModel, lessonNumber: Int) async throws {
//        let unitRef = firestore.collection("units").document(unitId)
//        
//        // Get the current unit data
//        let documentSnapshot = try await unitRef.getDocument()
//        guard documentSnapshot.exists else {
//            throw DbError.unitNotFound(unitId: unitId) // Create a custom error type
//        }
//        guard var unitData = documentSnapshot.data() else {
//            throw DbError.invalidUnitData(unitId: unitId)
//        }
//        
//        // Access and modify the lessons
//        guard var lessons = unitData["lessons"] as? [[String: Any]] else {
//            throw DbError.invalidUnitLessons(unitId: unitId)
//        }
//        
//        // Remove the lesson with the matching ID
//        lessons.removeAll { lesson in
//            // TODO remove image url
//            let imagePath = createImageFilePath(unit: unit, lessonNumber: lessonNumber, id: lesson["id"] as! String)
//            let audioPath = createAudioPath(unit: unit, lessonNumber: lessonNumber, id: lesson["id"] as! String)
//            Task {
//                try? await deleteImageFromFirebase(path: imagePath)
//                try? await deleteAudioFromFirebase(path: audioPath)
//            }
//            return lesson["id"] as? String == lessonId
//        }
//
//        // Update the unit document with the modified lessons array
//        unitData["lessons"] = lessons
//        try await unitRef.updateData(unitData)
//    }
    
    func createPurchaseRecord(_ purchaseRecord: PurchaseRecord) async throws -> String {
        let purchaseRecordsRef = firestore.collection("purchaseRecords")
        let documentRef = try purchaseRecordsRef.addDocument(from: purchaseRecord)
        return documentRef.documentID
    }
    
}

enum DbError: Error {
    case unitNotFound(unitId: String)
    case invalidUnitData(unitId: String)
    case invalidUnitLessons(unitId: String)
}
