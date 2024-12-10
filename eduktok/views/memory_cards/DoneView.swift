//
//  DoneView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 20/2/24.
//

import SwiftUI

struct DoneView: View {
    let userModel: UserModel
    @StateObject private var viewModel = DoneViewModel()
    @State private var searchText = ""
    @State private var isLoading = true
    
    var filteredTemplates: [TemplateModel] {
        let templates: [TemplateModel] = $viewModel.doneTemplates.wrappedValue
        if searchText.isEmpty {
            return templates.sorted(by: { $0.dateCreated.dateValue() > $1.dateCreated.dateValue() })
        } else {
            return templates.filter { template in
                template.tags.contains(where: { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                })
            }
            .sorted(by: { $0.dateCreated.dateValue() > $1.dateCreated.dateValue() }) // Sorting by dateCreated
        }
    }
    
    var body: some View {
        VStack {
            if isLoading {  // Show progress view while loading
                ProgressView()
            } else {
                if $viewModel.doneTemplates.isEmpty {
                    Text("No memory cards have been marked as done")
                }
                else {
                    NavigationStack {
                        List {
                            ForEach(filteredTemplates, id: \.id) { template in
                                DoneCardView(template: template)
                                    .padding(.bottom, 10)
                            }
                        }
                        .searchable(text: $searchText, prompt: Text("Search by tag"))
                        .navigationTitle("Memory Cards Completed")
                    }
                }
            }
        }
        .onAppear{
            Task{
                viewModel.fetchDoneTemplates(userModel: userModel)
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                isLoading = false
            }
        }
    }
}
