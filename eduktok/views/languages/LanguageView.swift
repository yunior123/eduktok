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
    private let languages = ["English", "German", "French", "Spanish", "Italian", "Chinese", "Portuguese", "Russian", "Japanese", "Korean"]
    let userModel: UserModel
    @StateObject private var viewModel = LanguageViewModel()
    let isPro: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                OrignaLBackdrop()

                VStack(alignment: .leading, spacing: 14) {
                    hero

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(languages, id: \.self) { language in
                                LanguageButton(
                                    language: language,
                                    isSelected: language == selectedLanguage,
                                    action: {
                                    selectedLanguage = language
                                    userModel.learningLanguage = language
                                    Task {
                                        do {
                                            try await Db().updateUser(user: userModel)
                                        } catch {
                                            print("Failed to update preferred language: \\(error.localizedDescription)")
                                        }
                                    }
                                }
                            )
                                .accessibilityIdentifier("language.\(language.lowercased())")
                            }
                        }
                        .padding(.horizontal, 2)
                    }

                    CardGridView(
                        unitProgress: calculateUnitProgress(for: selectedLanguage),
                        units: viewModel.units.sorted { $0.unitNumber < $1.unitNumber },
                        userModel: userModel,
                        selectedLanguage: selectedLanguage,
                        isPro: isPro
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedLanguage = userModel.learningLanguage ?? "English"
                viewModel.fetchUnits()
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From first sounds to full conversations")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(OrignaLTheme.ice)
            Text("Language: \(selectedLanguage)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OrignaLTheme.ice.opacity(0.88))
        }
        .padding(14)
        .orignalGlassCard()
    }

    private func calculateUnitProgress(for language: String) -> [String: Int] {
        guard let languageData = userModel.languageProgress?[language] else { return [:] }

        var progress: [String: Int] = [:]
        for (unitName, lessons) in languageData {
            progress[unitName] = lessons.filter { $1 }.count
        }
        return progress
    }
}

struct LanguageButton: View {
    let language: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(language)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected
                    ? OrignaLTheme.buttonGradient
                    : LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(isSelected ? Color.black : OrignaLTheme.ice)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct CardGridView: View {
    let unitProgress: [String: Int]
    let units: [UnitModel]
    let userModel: UserModel
    let selectedLanguage: String
    let isPro: Bool

    private let freeUnitsCount = 25

    var body: some View {
        if units.isEmpty {
            VStack(spacing: 10) {
                ProgressView()
                    .tint(OrignaLTheme.mint)
                Text("Preparing your lessons...")
                    .foregroundStyle(OrignaLTheme.ice.opacity(0.85))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 164), spacing: 14)], spacing: 14) {
                    ForEach(units, id: \.id) { unit in
                        unitCard(unit)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private func unitCard(_ unit: UnitModel) -> some View {
        let key = unit.id ?? "unit_\(unit.unitNumber)"
        let progress = unitProgress[key] ?? 0
        let canAccess = isPro || unit.unitNumber <= freeUnitsCount

        if canAccess {
            NavigationLink(destination: LessonView(unit: unit, userModel: userModel, selectedLanguage: selectedLanguage)) {
                UnitCardView(unit: unit, progress: progress, selectedLanguage: selectedLanguage)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("unit.card.\(unit.unitNumber)")
        } else {
            UnitCardView(unit: unit, progress: progress, selectedLanguage: selectedLanguage)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.52))
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundStyle(OrignaLTheme.warning)
                                Text("Lifetime unlock")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(OrignaLTheme.ice)
                            }
                        }
                }
                .accessibilityIdentifier("unit.locked.\(unit.unitNumber)")
        }
    }
}

struct UnitCardView: View {
    let unit: UnitModel
    let progress: Int
    let selectedLanguage: String
    private let expectedLessons = 30

    private var localizedTitle: String {
        let code = convertToLanguageCode(selectedLanguage) ?? "en"
        return unit.title[code] ?? unit.title["en"] ?? "Build your language foundation"
    }

    private var progressRatio: Double {
        min(1, max(0, Double(progress) / Double(expectedLessons)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CachedAsyncImage(url: unit.imageUrl, placeholder: Image(systemName: "photo"))
                .frame(height: 108)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(unit.unitName)
                .font(.caption.weight(.heavy))
                .foregroundStyle(OrignaLTheme.mint)

            Text(localizedTitle)
                .font(.headline.weight(.bold))
                .foregroundStyle(OrignaLTheme.ice)
                .lineLimit(2)

            ProgressView(value: progressRatio)
                .tint(OrignaLTheme.mint)

            Text("\(progress)/\(expectedLessons) lessons")
                .font(.caption2.weight(.bold))
                .foregroundStyle(OrignaLTheme.ice.opacity(0.88))
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .topLeading)
        .orignalGlassCard()
    }
}
