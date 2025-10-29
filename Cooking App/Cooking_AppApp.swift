//
//  Cooking_AppApp.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import SwiftUI

@main
struct Cooking_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // TODO: Add .modelContainer(for: Recipe.self) when Recipe conforms to PersistentModel
    }
}

// MARK: - App Launch Setup
extension Cooking_AppApp {
    private func setupApp() {
        // Configure app-wide settings
        setupAppearance()
    }
    
    private func setupAppearance() {
        // Customize navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
