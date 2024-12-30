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
    let languages = ["English","German", "French", "Spanish","Italian","Chinese","Portuguese","Russian","Japanese","Korean"]
    let userModel: UserModel
    @StateObject private var viewModel = LanguageViewModel()
    let isPro: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(languages, id: \.self) { language in
                            LanguageButton(
                                language: language,
                                isSelected: language == selectedLanguage,
                                action: {
                                    selectedLanguage = language
                                    userModel.learningLanguage = language
                                    let db = Db()
                                    Task {
                                        try await db.updateUser(user: userModel)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
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
                    viewModel.fetchUnits()
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

struct LanguageButton: View {
    let language: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(language)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}


struct CardGridView: View {
    let unitProgress: [String: Int]
    let units: [UnitModel]
    let userModel: UserModel
    let selectedLanguage: String
    let isPro: Bool
    
    // Calculate rows based on dynamic column count
    private func rows(in geometry: GeometryProxy) -> [[UnitModel]] {
        let minCardWidth: CGFloat = 150
        let spacing: CGFloat = 10
        let availableWidth = geometry.size.width - 32 // Account for horizontal padding
        let optimalColumnCount = max(2, Int(availableWidth / (minCardWidth + spacing)))
        
        var result: [[UnitModel]] = []
        var currentRow: [UnitModel] = []
        
        for unit in units {
            currentRow.append(unit)
            if currentRow.count == optimalColumnCount {
                result.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            result.append(currentRow)
        }
        
        return result
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Grid(horizontalSpacing: 10, verticalSpacing: 15) {
                    let gridRows = rows(in: geometry)
                    ForEach(gridRows.indices, id: \.self) { rowIndex in
                        GridRow {
                            ForEach(gridRows[rowIndex], id: \.id) { unit in
                                ZStack {
                                    if isPro || (unit.unitNumber - 1) < units.count / 2 {
                                        NavigationLink(destination: LessonView(unit: unit, userModel: userModel, selectedLanguage: selectedLanguage)) {
                                            UnitCardView(
                                                unit: unit,
                                                progress: unitProgress[unit.id!] ?? 0,
                                                userModel: userModel,
                                                selectedLanguage: selectedLanguage
                                            )
                                        }
                                    } else {
                                        UnitCardView(
                                            unit: unit,
                                            progress: unitProgress[unit.id!] ?? 0,
                                            userModel: userModel,
                                            selectedLanguage: selectedLanguage
                                        )
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
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct UnitCardView: View {
    let unit: UnitModel
    let progress: Int
    let userModel: UserModel
    @State private var showDeleteAlert = false // State to control the alert
    let selectedLanguage: String
    
    func getTitle() -> String {
        let langCode = convertToLanguageCode(selectedLanguage)!;
        let title = unit.title[langCode]!
        return title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(unit.unitName)
                .font(.headline)
                .foregroundColor(.blue)
            Text(getTitle())
                .lineLimit(2)
                .foregroundColor(.blue)
            
            CachedAsyncImage(url: unit.imageUrl, placeholder: Image(systemName: "photo"))
                .frame(maxHeight: 150) // Constrain image height
                .clipped()
            
            Text("Progress: \(progress)/\(40)")
                .foregroundColor(.blue)
                .font(.caption).bold()
            
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
