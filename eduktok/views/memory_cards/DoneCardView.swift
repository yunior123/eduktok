//
//  DoneCardView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 20/2/24.
//

import SwiftUI
import FirebaseFirestore


struct DoneCardView: View {
    let template: TemplateModel
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
            
            HStack {
                Text("Next Date: \(template.nextDate.dateValue(), formatter: dateFormatter)")
                Spacer()
            }
            
            
            TagsListView(template: template)
            
            HStack {
                Button("Restore", action: {
                })
                .onTapGesture {
                    Task{
                        await onRestored(template: template)
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

func onRestored(template: TemplateModel) async {
    let db = Db()
    let updatedTemplate = template.copyWith(
        nextDate: Timestamp(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        intervals: [2, 3, 7, 15, 30, 60, 120, 240, 480, 960]
    )
    
    do {
        try await db.updateTemplate(template: updatedTemplate)
    } catch {
        // Handle the error
        print("Error updating template")
    }
}
