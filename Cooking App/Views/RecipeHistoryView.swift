//
//  RecipeHistoryView.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import SwiftUI

struct RecipeHistoryView: View {
    @EnvironmentObject var recipeGenerator: RecipeGenerator
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecipe: Recipe?
    
    var body: some View {
        NavigationStack {
            Group {
                if recipeGenerator.generatedRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife.circle",
                        description: Text("Generate some recipes to see them here!")
                    )
                } else {
                    List {
                        ForEach(recipeGenerator.generatedRecipes) { recipe in
                            RecipeHistoryRow(recipe: recipe)
                                .onTapGesture {
                                    selectedRecipe = recipe
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button("Delete", role: .destructive) {
                                        recipeGenerator.deleteRecipe(recipe)
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Recipe History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !recipeGenerator.generatedRecipes.isEmpty {
                        Button("Clear All", role: .destructive) {
                            recipeGenerator.clearHistory()
                        }
                    }
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                NavigationStack {
                    RecipeDetailView(recipe: recipe)
                        .navigationTitle("Recipe Details")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedRecipe = nil
                                }
                            }
                        }
                }
            }
        }
    }
}

struct RecipeHistoryRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: recipe.category.systemImage)
                .font(.title2)
                .foregroundStyle(Color.orange)
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(recipe.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Label("\(recipe.cookingTime)m", systemImage: "clock")
                    Label("\(recipe.servings)", systemImage: "person.2")
                    Label(recipe.difficulty.rawValue, systemImage: recipe.difficulty.systemImage)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(recipe.dateCreated, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RecipeDisplayView(recipe: recipe)
                
                // Additional details for history view
                VStack(alignment: .leading, spacing: 12) {
                    Text("Generation Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Generated:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(recipe.dateCreated, style: .date)
                        }
                        
                        HStack {
                            Text("Time:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(recipe.dateCreated, style: .time)
                        }
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        RecipeHistoryView()
            .environmentObject({
                let generator = RecipeGenerator()
                return generator
            }())
    }
}