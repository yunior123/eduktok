//
//  SearchTagViewModel.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 21/2/24.
//

import Foundation
import SwiftUI

class SearchTagsViewModel: ObservableObject {
    @Published var allTags: [String] = []
    @Published var filteredTags: [String] = []
    @Published var isLoading = false



 

    // ...  You might need a function to filter tags based on searchQuery ...
}
