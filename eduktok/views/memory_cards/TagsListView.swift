//
//  TagsListView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 22/2/24.
//

import SwiftUI

struct TagsListView: View {
    let template: TemplateModel

    var body: some View {
        ScrollView(.horizontal) { // Enable horizontal scrolling
            HStack {
                ForEach(template.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .padding(5)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                Spacer() // Push tags to the left
            }
        }
    }
}
