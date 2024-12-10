//
//  SwiftUIView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 19/3/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

enum Language: String, CaseIterable, Identifiable {
    case english = "English"
    case german = "German"
    case french = "French"
    case spanish = "Spanish"
    
    var id: String { self.rawValue }
}

struct UnitCreationView: View {
    @State private var title: String = ""
    @State private var selectedLanguage: Language = .english // Default to English
    @State private var image: UIImage?
    @State private var lessons: [any LessonModel] = []
    @State private var selectedLessonType: GLanguageSkill = .GListening
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorDescription: String? = nil
    
    var body: some View {
        VStack (alignment: .center) {
            Text("Create Unit")
                .font(.title)
            
            VStack (alignment: .center) {
                TextField("Title", text: $title)
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.rawValue).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                
                ImageDropper(image: $image)
                
                Button("Create Unit") {
                    isLoading = true // Start loading animation
                    
                    Task {
                        await createUnit()
                        isLoading = false // Stop loading animation
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .buttonBorderShape(.roundedRectangle(radius: 20))
                .frame(maxWidth: .infinity)
                .overlay( // Add an overlay for the loading indicator
                    ProgressView()
                        .opacity(isLoading ? 1 : 0)
                )
                .disabled(isLoading) // Disable interaction while loading
                
            }
            .padding(15)
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {} // Add an action if needed
            } message: {
                Text("Unit created successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {} // Add an action if needed
            } message: {
                if let errorDescription = errorDescription {
                    Text(errorDescription)
                } else {
                    Text("An error occurred while creating the unit.")
                }
            }
        }
    }
    
    private func createUnit() async {
        // 1. Input Validation
        guard !title.isEmpty, image != nil else {
            print("Incomplete unit information. Please fill in all required fields.")
            return // Exit if the required information is missing
        }
        
        // 2. Fetch the highest unit number from Firestore
        do {
            let highestUnitNumber = try await fetchHighestUnitNumber(language: selectedLanguage.rawValue)
            
            guard let highestUnitNumber = highestUnitNumber else {
                return
            }
            let newUnitNumber = highestUnitNumber + 1
            // Convert UIImage to Data
            guard let imageData = image?.jpegData(compressionQuality: 0.5) else {
                print("Failed to convert image to data")
                return
            }
            //TODO: delete image as well when removing unit
            // 3. Upload image to Firebase Storage and get the download URL
            let imageUrl = try await uploadImageToFirebaseC(image: imageData, path:
                                                                createImagePath(unitNumber: newUnitNumber, selectedLanguage: selectedLanguage)
                                                            
            )
            // 3. Create UnitModel
            let unit = UnitModel(id: UUID().uuidString,
                                 unitName: "Unit \(newUnitNumber)", // Dynamic unit name
                                 unitNumber: newUnitNumber,
                                 title: title,
                                 imageUrl: imageUrl,
                                 lessons: lessons,
                                 language: selectedLanguage.rawValue)
            
            // 4. Call function to upload the unit data to Firestore
            try await uploadUnitDataToFirestore(unit: unit)
            showSuccess = true  // Show success pop-up
            
        } catch {
            print("Error creating unit: \(error.localizedDescription)")
            errorDescription = error.localizedDescription  // Store error
            showError = true   // Show error pop-up
        }
    }
}

private func fetchHighestUnitNumber(language: String) async throws -> Int? {
    let db = Firestore.firestore() // Initialize Firestore
    
    // Assuming 'units' is the name of your Firestore collection
    let query = db.collection("units")
        .whereField("language", isEqualTo: language)
        .order(by: "unitNumber", descending: true).limit(to: 1)
    
    let querySnapshot = try await query.getDocuments()
    
    guard let lastDocument = querySnapshot.documents.first else {
        return 0 // If there are no units, start with 0
    }
    
    // Extract the unitNumber from the last document and return it.
    if let unitNumber = lastDocument.data()["unitNumber"] as? Int {
        return unitNumber
    } else {
        return nil
    }
}

struct ImageDropper: View {
    @Binding var image: UIImage?
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Drop Image Here")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.3))
            }
        }
        .frame(width: 200, height: 200)
        .border(Color.gray)
        .onDrop(of: ["public.image"], isTargeted: nil) { providers, _ in
            self.loadImage(from: providers)
            return true
        }
    }
    
    private func loadImage(from providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { item, error in
                    guard let image = item as? UIImage else { return }
                    DispatchQueue.main.async {
                        self.image = image
                    }
                }
            }
        }
    }
}
