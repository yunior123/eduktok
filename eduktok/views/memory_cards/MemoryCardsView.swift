//
//  MemoryCards.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 22/3/24.
//
import SwiftUI

struct TileItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
}

struct MemoryCardsView: View {
    @State private var selectedTile: TileItem? = nil
    let userModel: UserModel
    
    let tileItems = [
        TileItem(title: "All"),
        TileItem(title: "Done"),
        TileItem(title: "Add")
    ]

    var body: some View {
        NavigationStack {
            List(tileItems) { item in
                NavigationLink(destination: destinationView(for: item, userModel: userModel)) {
                    Label(item.title, systemImage: systemImage(for: item))
                }
            }
            .navigationTitle("Memory Cards")
        }
    }
    
    func systemImage(for item: TileItem) -> String {
          switch item.title {
          case "All":
              return "checklist"
          case "Done":
              return "checkmark.circle"
          case "Add":
              return "plus.circle"
          default:
              return "circle"
          }
      }
    
    func destinationView(for item: TileItem, userModel: UserModel) -> some View {
        switch item.title {
        case "All":
            return AnyView(FeedView(userModel: userModel))
        case "Done":
            return AnyView(DoneView(userModel: userModel))
        case "Add":
            return AnyView(AddTemplateView(userModel: userModel))
        default:
            return AnyView(Text("Default View"))
        }
    }

}


