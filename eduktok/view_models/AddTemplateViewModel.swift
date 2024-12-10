//
//  AddTemplateViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 19/2/24.
//

import SwiftUI
import Firebase

class AddTemplateViewModel: ObservableObject {
    let userModel: UserModel
    @Published var title = ""
    @Published var description = ""
    @Published var tags = ""
    @Published var url = ""
    @Published var isShowingError = false
    @Published var errorMessage: String?
    
    @Published var image: UIImage?
    
    init(userModel: UserModel) {
        self.userModel = userModel
    }
    
    var canAddTemplate: Bool {
        !title.isEmpty && !tags.isEmpty
    }
    
    func selectImage() {
        ImagePicker.shared.show { image in
            self.image = image
        }
    }
    func deleteImage() {
        image = nil // Remove the image
    }
    
    func validateAndAddTemplate() async -> Bool {
        guard !title.isEmpty, !tags.isEmpty else {
            self.errorMessage = "Title and tags cannot be empty"
            self.isShowingError = true
            return false
        }
        
        if !url.isEmpty, !isValidUrl(urlString: url) {
            self.errorMessage = "Please enter a valid URL"
            self.isShowingError = true
            return false
        }
        
        let tagsList = tags.split(whereSeparator: { ", -_".contains($0) })
            .map { String($0) }
        
        let now = Date()
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) else {
            return false
        }
        let id = UUID().uuidString
        
        var imageUrl: URL?
        if let image = image {
            do {
                // Convert UIImage to Data
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    return false
                }
                // TODO: be able to eliminate image as well
                imageUrl = try await uploadImageToFirebaseC(image: imageData, path: "images/memory_cards_\(id)")
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        let newTemplate = TemplateModel(
            id: id,
            tags: tagsList,
            title: title,
            description: description,
            url: url.isEmpty ? nil : URL(string: url),
            imageUrl: imageUrl,
            nextDate: Timestamp(date: yesterday),
            intervals: [1, 3, 7, 15, 30, 60, 120, 240, 480, 960],
            createdBy: userModel.id,
            dateCreated: Timestamp(date: Date())
        )
        
        do {
            let db = Db()
            let templateId = try await db.addTemplate(template: newTemplate)
            try await db.updateTemplate(template: newTemplate.copyWith(id: templateId))
            let currentTags = userModel.tags ?? []
            let allTags = tagsList + currentTags
            let updatedUserTags = Array(Set(allTags))
            let newUserModel = userModel.copyWith(tags: updatedUserTags)
            try await db.updateUser(user: newUserModel)
            
        } catch {
            self.errorMessage = "Error saving template: \(error.localizedDescription)"
            self.isShowingError = true
            return false
        }
        
        return true
    }
    
    private func isValidUrl(urlString: String?) -> Bool {
        guard let urlString = urlString, let url = URL(string: urlString)  else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

enum CustomError: Error {
    case imageDataConversionFailure
}
