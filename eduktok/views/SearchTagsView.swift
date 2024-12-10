//
//  SearchPageView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//

import SwiftUI
import FirebaseFirestore

struct SearchPageView: View {
    @StateObject private var viewModel = SearchTagsViewModel() // Use a ViewModel
    @State private var searchQuery = ""

    var body: some View {
        NavigationView {
            List { // Equivalent of Flutter's ListView.builder
                ForEach(viewModel.filteredTags, id: \.self) { tag in
                    Text(tag)
                        .onTapGesture {
                            searchQuery = tag
                            viewModel.isLoading = true // Assuming a loader in the ViewModel
                            // Initiate a search on the HomePage (modify as needed)
//                            NavigationLink(destination: HomePage(searchTag: tag)) {
//                                EmptyView() // Avoid list highlighting, but triggers NavigationLink
//                            }
                        }
                }
            }
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always)) // SwiftUI's Search Integration
            .navigationTitle("Search")
            .onAppear {
               // viewModel.fetchTags()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView() // Show loading indicator
                }
            }
        }
    }
}


#Preview {
    SearchPageView()
}
