//
//  FeedView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 20/2/24.
//

import SwiftUI

struct FeedView: View {
    let userModel: UserModel
    @State private var isLoading = true
    @StateObject private var viewModel = FeedViewModel()
    @State private var searchText = ""
    var filteredTemplates: [TemplateModel] {
        if searchText.isEmpty {
            return viewModel.templates.sorted(by: { $0.dateCreated.dateValue() > $1.dateCreated.dateValue() })
        } else {
            return viewModel.templates.filter { template in
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
            } else if viewModel.templates.isEmpty {
                Text("No memory cards have been created")
            } else{
                NavigationStack {
                    List {
                        ForEach(filteredTemplates, id: \.id) { template in
                            FeedCardView(template: template, user: userModel)
                                .padding(.bottom, 10)
                        }
                    }
                    .searchable(text: $searchText, prompt: Text("Search by tag")) 
                    .navigationTitle("Memory Cards")
                }
                
            }
        }
        .onAppear{
            Task{
                viewModel.fetchTemplates(userModel: userModel)
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                isLoading = false
            }
        }
    }
}
