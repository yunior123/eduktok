//
//  LCardsGridView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 14/3/24.
//

import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import Firebase

struct LanguageView: View {
    @State private var selectedLanguage = "English"
    let languages = ["English","German", "French", "Spanish"]
    let userModel: UserModel
    @StateObject private var viewModel = LanguageViewModel()
    let isPro: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .onChange(of: selectedLanguage) { old, newLanguage in
                    userModel.learningLanguage = newLanguage
                    let db = Db()
                    Task {
                        try await db.updateUser(user: userModel)
                        
                        viewModel.fetchUnits(language: selectedLanguage)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                CardGridView(
                    unitProgress: calculateUnitProgress(for: selectedLanguage),
                    units: $viewModel.units.wrappedValue.sorted { $0.unitNumber < $1.unitNumber },
                    userModel: userModel,
                    selectedLanguage: selectedLanguage,
                    isPro: isPro
                )
                
            }
            .onAppear{
                selectedLanguage = userModel.learningLanguage ?? "English"
                Task{
                    viewModel.fetchUnits(language: selectedLanguage)
                }
            }
            .padding(.top, 0)
            
        }
        
        
    }
    
    private func calculateUnitProgress(for language: String) -> [String: Int] {
        guard let languageData = userModel.languageProgress?[language] else { return [:] }
        
        var unitProgress: [String: Int] = [:]
        for (unitName, lessons) in languageData {
            let completedLessons = lessons.filter { $1 == true }.count // Count completed lessons
            unitProgress[unitName] = completedLessons
        }
        return unitProgress
    }
}


struct CardGridView: View {
    let unitProgress: [String: Int]
    let units: [UnitModel]
    let userModel: UserModel
    let selectedLanguage: String
    let isPro: Bool
    let gridLayout = [
        GridItem(.adaptive(minimum: 150, maximum: 250), spacing: 10),
        GridItem(.adaptive(minimum: 150, maximum: 250), spacing: 10),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout, spacing: 15) {
                ForEach(
                    units,
                    id: \.id
                ) { unit in
                    ZStack {
                        // If the user does not have lifetime access, they only get half the units.
                        // Determine if the card should be interactive
                        if isPro || (unit.unitNumber - 1) < units.count / 2 {
                            NavigationLink(destination: LessonView(unit: unit, userModel: userModel, selectedLanguage: selectedLanguage)) {
                                UnitCardView(unit: unit, progress: unitProgress[unit.id!] ?? 0, userModel: userModel)
                            }
                            .disabled(unit.lessons.isEmpty)
                        } else {
                            UnitCardView(unit: unit, progress: unitProgress[unit.id!] ?? 0, userModel: userModel)
                                .overlay(
                                    Color.black.opacity(0.5)
                                        .cornerRadius(10)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "crown.fill")
                                                    .foregroundColor(.yellow)
                                                    .font(.title)
                                                Text("Unlock with premium")
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                                    .padding()
                                            }
                                                .padding()
                                            
                                        )
                                )
                        }
                    }
                }
            }
            .padding(.top, 0)
        }
    }
}

struct UnitCardView: View {
    let unit: UnitModel
    let progress: Int
    let userModel: UserModel
    @State private var showDeleteAlert = false // State to control the alert
    
    func deleteUnitData(unit: UnitModel) {
        // 1. Firestore Deletion
        let db = Firestore.firestore() // Get Firestore instance
        db.collection("units").document(unit.id!).delete() { error in
            if let error = error {
                print("Error deleting Firestore document: \(error)")
            } else {
                print("Firestore document deleted successfully")
            }
        }
        
        // 2. Storage Deletion
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("images/unit_\(unit.unitNumber)_\(unit.language.lowercased()).jpg")
        
        imageRef.delete { error in
            if let error = error {
                print("Error deleting Storage image: \(error)")
            } else {
                print("Storage image deleted successfully")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(unit.unitName)
                .font(.headline)
                .foregroundColor(.blue)
            Text(unit.title)
                .lineLimit(2)
                .foregroundColor(.blue)
            
            CachedAsyncImage(url: unit.imageUrl, placeholder: Image(systemName: "photo"))
                .frame(maxHeight: 150) // Constrain image height
                .clipped()
            
            Text("Progress: \(progress)/\(unit.lessons.count)")
                .foregroundColor(.blue)
                .font(.caption).bold()
            
            if userModel.role == "admin" {
                Button("Delete Unit") {
                    showDeleteAlert = true // Show the confirmation alert
                }
                .font(.caption).bold()
                .foregroundColor(.red)
                .alert("Confirm Delete", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        deleteUnitData(unit: unit)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to delete all data for this unit? This action is irreversible.")
                }
            }
        }
        .padding()
        .frame(maxWidth: 250, maxHeight: 300) // Set max width and height
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .shadow(radius: 1)
    }
}

