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

/// Database service for Eduktok app - handles all Firebase Firestore operations
class Db {
    let firestore = Firestore.firestore()
    
    // MARK: - Constants
    private enum Collections {
        static let units = "unitsNew"
        static let lessons = "lessonsNew"
        static let users = "users"
        static let purchaseRecords = "purchaseRecords"
    }
    
    // MARK: - Lesson Operations
    
    /// Fetch all lessons for a specific unit
    /// - Parameter unitNumber: The unit number to fetch lessons for
    /// - Returns: Array of Firestore document snapshots containing lesson data
    /// - Throws: FirebaseError if fetch fails
    func fetchLessonsForUnit(unitNumber: Int) async throws -> [DocumentSnapshot] {
        guard unitNumber > 0 else {
            throw DbError.invalidUnitNumber(unitNumber)
        }
        
        do {
            let lessonsSnapshot = try await firestore.collection(Collections.lessons)
                .whereField("unitNumber", isEqualTo: unitNumber)
                .order(by: "lessonNumber")
                .getDocuments()
            
            print("✅ Fetched \(lessonsSnapshot.documents.count) lessons for unit \(unitNumber)")
            return lessonsSnapshot.documents
        } catch {
            print("❌ Failed to fetch lessons for unit \(unitNumber): \(error.localizedDescription)")
            throw DbError.fetchFailed(collection: Collections.lessons, reason: error.localizedDescription)
        }
    }
    
    /// Fetch a specific lesson by ID
    /// - Parameters:
    ///   - lessonId: The unique identifier of the lesson
    ///   - unitNumber: The unit number the lesson belongs to
    /// - Returns: Document snapshot of the lesson
    /// - Throws: DbError if lesson not found or fetch fails
    func fetchLesson(lessonId: String, unitNumber: Int) async throws -> DocumentSnapshot {
        do {
            let document = try await firestore.collection(Collections.lessons)
                .document(lessonId)
                .getDocument()
            
            guard document.exists else {
                throw DbError.lessonNotFound(lessonId: lessonId)
            }
            
            return document
        } catch let error as DbError {
            throw error
        } catch {
            throw DbError.fetchFailed(collection: Collections.lessons, reason: error.localizedDescription)
        }
    }
    
    // MARK: - User Operations
    
    /// Find a user by email address
    /// - Parameter email: The email address to search for
    /// - Returns: UserModel if found, nil otherwise
    /// - Throws: DbError if search fails
    func findUser(email: String) async throws -> UserModel? {
        guard !email.isEmpty else {
            throw DbError.invalidEmail(email)
        }
        
        do {
            let usersRef = firestore.collection(Collections.users)
            let query = usersRef.whereField("email", isEqualTo: email).limit(to: 1)
            let querySnapshot = try await query.getDocuments()
            
            let user = querySnapshot.documents.compactMap { document in
                guard let userModel = UserModel(from: document, id: document.documentID) else {
                    print("❌ Error creating UserModel from document: \(document.documentID)")
                    return nil
                }
                return userModel
            }.first
            
            if user != nil {
                print("✅ Found user with email: \(email)")
            } else {
                print("⚠️ No user found with email: \(email)")
            }
            
            return user
        } catch {
            print("❌ Failed to find user with email \(email): \(error.localizedDescription)")
            throw DbError.fetchFailed(collection: Collections.users, reason: error.localizedDescription)
        }
    }
    
    /// Create a new user in the database
    /// - Parameter user: The UserModel to create
    /// - Returns: The document ID of the created user
    /// - Throws: DbError if creation fails
    func createUser(_ user: UserModel) async throws -> String {
        do {
            let usersRef = firestore.collection(Collections.users)
            let documentRef = try usersRef.addDocument(from: user)
            print("✅ Created user with ID: \(documentRef.documentID)")
            return documentRef.documentID
        } catch {
            print("❌ Failed to create user: \(error.localizedDescription)")
            throw DbError.createFailed(collection: Collections.users, reason: error.localizedDescription)
        }
    }
    
    /// Delete a user by ID
    /// - Parameter id: The document ID of the user to delete
    /// - Throws: DbError if deletion fails
    func deleteUser(id: String) async throws {
        guard !id.isEmpty else {
            throw DbError.invalidId(id)
        }
        
        do {
            let docRef = firestore.collection(Collections.users).document(id)
            try await docRef.delete()
            print("✅ Deleted user with ID: \(id)")
        } catch {
            print("❌ Failed to delete user \(id): \(error.localizedDescription)")
            throw DbError.deleteFailed(collection: Collections.users, documentId: id, reason: error.localizedDescription)
        }
    }
    
    // MARK: - Generic Update Operations
    
    /// Update a single document with given data
    /// - Parameters:
    ///   - collection: The collection name
    ///   - docId: The document ID to update
    ///   - model: Dictionary containing the fields to update
    /// - Throws: DbError if update fails
    func fsTaskUpdateOneDocWithId(collection: String, docId: String, model: [String: Any]) async throws {
        guard !collection.isEmpty, !docId.isEmpty else {
            throw DbError.invalidUpdateParameters(collection: collection, docId: docId)
        }
        
        do {
            let docRef = firestore.collection(collection).document(docId)
            try await docRef.updateData(model)
            print("✅ Updated document \(docId) in collection \(collection)")
        } catch {
            print("❌ Failed to update document \(docId) in \(collection): \(error.localizedDescription)")
            throw DbError.updateFailed(collection: collection, documentId: docId, reason: error.localizedDescription)
        }
    }
    
    /// Update a user's data in the database
    /// - Parameter user: The UserModel with updated data
    /// - Throws: DbError if encoding or update fails
    func updateUser(user: UserModel) async throws {
        guard let encodedData = try? JSONEncoder().encode(user) else {
            print("❌ Error encoding user")
            throw DbError.encodingFailed(type: "UserModel")
        }
        
        guard let model = try? JSONSerialization.jsonObject(with: encodedData) as? [String: Any] else {
            print("❌ Error converting user to dictionary")
            throw DbError.serializationFailed(type: "UserModel")
        }
        
        try await fsTaskUpdateOneDocWithId(collection: Collections.users, docId: user.id, model: model)
    }
    
    // MARK: - Listeners
    
    /// Create a listener for units collection
    /// - Returns: Query object that can be observed for changes
    func unitsListener() -> Query {
        return firestore.collection(Collections.units)
            .order(by: "unitNumber")
    }
    
    /// Create a listener for a specific user by email
    /// - Parameter email: The email address to listen for
    /// - Returns: Query object that can be observed for user changes
    func userListener(email: String) -> Query {
        return firestore.collection(Collections.users)
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
    
    // MARK: - Purchase Operations
    
    /// Create a purchase record in the database
    /// - Parameter purchaseRecord: The purchase record to save
    /// - Returns: The document ID of the created record
    /// - Throws: DbError if creation fails
    func createPurchaseRecord(_ purchaseRecord: PurchaseRecord) async throws -> String {
        do {
            let purchaseRecordsRef = firestore.collection(Collections.purchaseRecords)
            let documentRef = try purchaseRecordsRef.addDocument(from: purchaseRecord)
            print("✅ Created purchase record with ID: \(documentRef.documentID)")
            return documentRef.documentID
        } catch {
            print("❌ Failed to create purchase record: \(error.localizedDescription)")
            throw DbError.createFailed(collection: Collections.purchaseRecords, reason: error.localizedDescription)
        }
    }
    
    // MARK: - Unit Operations
    
    /// Fetch all units
    /// - Returns: Array of UnitModel objects
    /// - Throws: DbError if fetch fails
    func fetchAllUnits() async throws -> [UnitModel] {
        do {
            let snapshot = try await firestore.collection(Collections.units)
                .order(by: "unitNumber")
                .getDocuments()
            
            let units = snapshot.documents.compactMap { document in
                UnitModel(from: document)
            }
            
            print("✅ Fetched \(units.count) units")
            return units
        } catch {
            print("❌ Failed to fetch units: \(error.localizedDescription)")
            throw DbError.fetchFailed(collection: Collections.units, reason: error.localizedDescription)
        }
    }
    
    /// Fetch a specific unit by number
    /// - Parameter unitNumber: The unit number to fetch
    /// - Returns: UnitModel if found
    /// - Throws: DbError if not found or fetch fails
    func fetchUnit(unitNumber: Int) async throws -> UnitModel {
        guard unitNumber > 0 else {
            throw DbError.invalidUnitNumber(unitNumber)
        }
        
        do {
            let snapshot = try await firestore.collection(Collections.units)
                .whereField("unitNumber", isEqualTo: unitNumber)
                .limit(to: 1)
                .getDocuments()
            
            guard let document = snapshot.documents.first,
                  let unit = UnitModel(from: document) else {
                throw DbError.unitNotFound(unitId: "\(unitNumber)")
            }
            
            print("✅ Fetched unit \(unitNumber)")
            return unit
        } catch let error as DbError {
            throw error
        } catch {
            throw DbError.fetchFailed(collection: Collections.units, reason: error.localizedDescription)
        }
    }
    
}

// MARK: - Error Types

/// Custom errors for database operations
enum DbError: Error, LocalizedError {
    case unitNotFound(unitId: String)
    case lessonNotFound(lessonId: String)
    case invalidUnitData(unitId: String)
    case invalidUnitLessons(unitId: String)
    case invalidUnitNumber(Int)
    case invalidEmail(String)
    case invalidId(String)
    case invalidUpdateParameters(collection: String, docId: String)
    case fetchFailed(collection: String, reason: String)
    case createFailed(collection: String, reason: String)
    case updateFailed(collection: String, documentId: String, reason: String)
    case deleteFailed(collection: String, documentId: String, reason: String)
    case encodingFailed(type: String)
    case serializationFailed(type: String)
    
    var errorDescription: String? {
        switch self {
        case .unitNotFound(let unitId):
            return "Unit not found with ID: \(unitId)"
        case .lessonNotFound(let lessonId):
            return "Lesson not found with ID: \(lessonId)"
        case .invalidUnitData(let unitId):
            return "Invalid data for unit: \(unitId)"
        case .invalidUnitLessons(let unitId):
            return "Invalid lessons data for unit: \(unitId)"
        case .invalidUnitNumber(let number):
            return "Invalid unit number: \(number). Must be greater than 0"
        case .invalidEmail(let email):
            return "Invalid email address: \(email)"
        case .invalidId(let id):
            return "Invalid document ID: \(id)"
        case .invalidUpdateParameters(let collection, let docId):
            return "Invalid update parameters for collection: \(collection), docId: \(docId)"
        case .fetchFailed(let collection, let reason):
            return "Failed to fetch from \(collection): \(reason)"
        case .createFailed(let collection, let reason):
            return "Failed to create document in \(collection): \(reason)"
        case .updateFailed(let collection, let documentId, let reason):
            return "Failed to update document \(documentId) in \(collection): \(reason)"
        case .deleteFailed(let collection, let documentId, let reason):
            return "Failed to delete document \(documentId) from \(collection): \(reason)"
        case .encodingFailed(let type):
            return "Failed to encode \(type) to JSON"
        case .serializationFailed(let type):
            return "Failed to serialize \(type) to dictionary"
        }
    }
}
