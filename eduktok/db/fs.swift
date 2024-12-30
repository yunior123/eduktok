//
//  FireStoreApi.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 18/3/24.
//

import Foundation
import FirebaseStorage

// Firebase Storage Upload Functions
func uploadAudioToFirebaseC(audio: Data, path: String) async throws -> URL {
    // 1. Create a reference in Firebase Storage
    let storageRef = Storage.storage().reference().child(path) 
    
    // 2. Perform the upload task
    let metadata = StorageMetadata() // add any metadata if you like
    let _ = try await storageRef.putDataAsync(audio, metadata: metadata)
    
    // 3. Retrieve download URL
    let downloadURL = try await storageRef.downloadURL()
    return downloadURL
}

func uploadImageToFirebaseC(image: Data, path: String) async throws -> URL {
    // 1. Create a reference in Firebase Storage
    let storageRef = Storage.storage().reference().child(path)
    
    // 2. Check if the file already exists and delete it
    do {
        let _ = try await storageRef.getMetadata()
        try await storageRef.delete() // Delete the existing file
        print("Existing image deleted.")
    } catch {
        if let error = error as? NSError, error.domain == StorageErrorDomain,
           error.code == StorageErrorCode.objectNotFound.rawValue {
            print("No existing image to delete, proceeding with upload.")
        }
        print(error.localizedDescription)
    }
    
    // 3. Perform the upload task
    let metadata = StorageMetadata()
    let _ = try await storageRef.putDataAsync(image, metadata: metadata)

    // 4. Retrieve the download URL
    let downloadURL = try await storageRef.downloadURL()
    return downloadURL
}

// Firebase Storage Delete Functions
func deleteAudioFromFirebase(path: String) async throws {
  // 1. Create a reference to the file in Firebase Storage
  let storageRef = Storage.storage().reference().child(path)
  
  // 2. Delete the file
  try await storageRef.delete()
}

func deleteImageFromFirebase(path: String) async throws {
  // 1. Create a reference to the file in Firebase Storage
  let storageRef = Storage.storage().reference().child(path)
  
  // 2. Delete the file
  try await storageRef.delete()
}
