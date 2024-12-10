
import SwiftUI
import FirebaseFirestore


struct FeedCardView: View {
    let template: TemplateModel
    let user: UserModel
    @State private var imageUrl: URL?
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .center) {
                Text(template.title).font(.headline)
                if let description = template.description {
                    Text(description)
                }
                
                if let url = template.url {
                    Button("Open Url", action: {
                    })
                    .onTapGesture {
                        UIApplication.shared.open(url)
                    }
                    .frame(width: 100, height: 50)
                }
                
                if let imageUrl = template.imageUrl {
                    HStack {
                        Spacer()
                        CachedAsyncImage(url: imageUrl, placeholder: Image(systemName: "photo"))
                        Spacer()
                    }
 
                }
                
            }
            
            TagsListView(template: template)
            
            HStack {
                Button("Done", action: {
                })
                .onTapGesture {
                    Task{
                        await onDone(templateModel: template, user: user)
                    }
                }
                .frame(width: 100, height: 50)
                Spacer()
                Button(role: .destructive) {
                    
                } label: {
                    Label("Delete", systemImage: "trash")
                } .frame(width: 100, height: 50)
                    .onTapGesture {
                        Task{
                            deleteTemplate(id: template.id)
                        }
                    }
            }
        }
        
        .onAppear {
            if let imageUrl = template.imageUrl {
                self.imageUrl = imageUrl
            }
        }
    }
}

func deleteTemplate(id: String) {
    let db = Firestore.firestore()
    db.collection("templates").document(id).delete { error in
        if let error = error {
            print("Error deleting template: \(error)")
        } else {
            print("Template successfully deleted!")
        }
    }
}

@MainActor func onDone(templateModel: TemplateModel, user: UserModel) async  {
    let db = Db()
    
    var intervals = templateModel.intervals
    guard !intervals.isEmpty else { return }
    intervals.removeFirst() // Modify in-place
    
    let now = Date()
    guard let firstInterval = intervals.first else { return }
    let newNextDate = Calendar.current.date(byAdding: .day, value: firstInterval, to: now)!
    
    do {
        let updatedTemplate = templateModel.copyWith(nextDate: Timestamp(date: newNextDate), intervals: intervals)
        try await db.updateTemplate(template: updatedTemplate)
        
        for tag in templateModel.tags {
            var updatedTagsScore = user.tagsScore ?? [:]
            updatedTagsScore[tag] = (updatedTagsScore[tag] ?? 0) + 1
            
            let updatedUser = user.copyWith(tagsScore: updatedTagsScore)
            try await db.updateUser(user: updatedUser)
        }
    } catch {
        print("Error in onDone: \(error)")
    }
}

