//
//  MainView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 20/2/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.templates) { template in
                CardView(template: template, user: createRandomUser())
            }
            
        }
        .navigationTitle("Tasks")
        //        .sheet(isPresented: $viewModel.isAddingTemplate) {
        //            AddTemplateView(userModel: viewModel.userModel!) // Pass userModel
        //        }
        .onAppear {
            if viewModel.templates.isEmpty {
                Task{
                    try await self.viewModel.createUser()
                    self.viewModel.fetchTemplates()
                }
            }
        }
        Spacer()
        // Show TabView if userModel exists
        if let userModel = viewModel.userModel {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(1)
                    .id(1)
                
//                DoneView().tabItem {
//                    Label("Done", systemImage: "checkmark.circle")
//                }.tag(1).id(1)
                
                AddTemplateView(userModel:userModel).tabItem {
                    Label("Add", systemImage: "plus.circle")
                }.tag(2).id(2)
                
                SearchView().tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }.tag(3).id(3)
                
                SettingsView().tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(4).id(4)
            }
        }
        
    }
    
}
#Preview {
    MainView()
}
