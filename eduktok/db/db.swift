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
    
    func addTemplate(template: TemplateModel) async throws -> String {
        let collectionRef = firestore.collection("templates")
        let documentRef = try collectionRef.addDocument(from: template)
        return documentRef.documentID
    }
    
    func deleteTemplate(id: String) async throws {
        let docRef = firestore.collection("templates").document(id)
        try await docRef.delete()
    }
    
    func deleteTemplates(userId: String) async throws {
        let collectionRef = firestore.collection("templates")
        let querySnapshot = try await collectionRef.whereField("createdBy", isEqualTo: userId).getDocuments()
        
        for document in querySnapshot.documents {
            try await document.reference.delete()
        }
    }
    
    func deleteUser(id: String) async throws {
        let docRef = firestore.collection("users").document(id)
        try await docRef.delete()
    }
    
    func fsTaskUpdateOneDocWithId(collection: String, docId: String, model: [String: Any]) async throws {
        let docRef = firestore.collection(collection).document(docId)
        try await docRef.updateData(model)
    }
    
    
    func updateTemplate(template: TemplateModel) async throws{
        let docRef = firestore.collection("templates").document(template.id)
        try docRef.setData(from: template)
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
    
    func unitsListener(language: String ) -> Query {
        return firestore.collection("units")
            .whereField("language", isEqualTo: language)
    }
    
    func templatesListener(userId: String ) -> Query {
        return firestore.collection("templates")
            .whereField("nextDate", isLessThan: Timestamp(date: Date()))
            .whereField("createdBy", isEqualTo: userId)
        
    }
    
    func doneListener(userId: String) -> Query{
        firestore.collection("templates")
            .whereField("nextDate", isGreaterThan: Timestamp(date: Date()))
            .whereField("createdBy", isEqualTo: userId)
        
    }
    
    func userListener(email: String) -> Query {
        return firestore.collection("users")
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
    }
    
    func removeLessonFromUnit(unitId: String, lessonId: String, unit: UnitModel, lessonNumber: Int) async throws {
        let unitRef = firestore.collection("units").document(unitId)
        
        // Get the current unit data
        let documentSnapshot = try await unitRef.getDocument()
        guard documentSnapshot.exists else {
            throw DbError.unitNotFound(unitId: unitId) // Create a custom error type
        }
        guard var unitData = documentSnapshot.data() else {
            throw DbError.invalidUnitData(unitId: unitId)
        }
        
        // Access and modify the lessons
        guard var lessons = unitData["lessons"] as? [[String: Any]] else {
            throw DbError.invalidUnitLessons(unitId: unitId)
        }
        
        // Remove the lesson with the matching ID
        lessons.removeAll { lesson in
            // TODO remove image url
            let imagePath = createImageFilePath(unit: unit, lessonNumber: lessonNumber, id: lesson["id"] as! String)
            let audioPath = createAudioPath(unit: unit, lessonNumber: lessonNumber, id: lesson["id"] as! String)
            Task {
                try? await deleteImageFromFirebase(path: imagePath)
                try? await deleteAudioFromFirebase(path: audioPath)
            }
            return lesson["id"] as? String == lessonId
        }

        // Update the unit document with the modified lessons array
        unitData["lessons"] = lessons
        try await unitRef.updateData(unitData)
    }
    
}

enum DbError: Error {
    case unitNotFound(unitId: String)
    case invalidUnitData(unitId: String)
    case invalidUnitLessons(unitId: String)
}
