//
//  RecipeDisplayView.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import SwiftUI

struct RecipeDisplayView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with title and metadata
                VStack(alignment: .leading, spacing: 12) {
                    Text(recipe.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 16) {
                        // Category
                        Label(recipe.category.rawValue, systemImage: recipe.category.systemImage)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        
                        // Difficulty
                        Label(recipe.difficulty.rawValue, systemImage: recipe.difficulty.systemImage)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(recipe.difficulty.color.opacity(0.1))
                            .foregroundStyle(recipe.difficulty.color)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        // Time and servings
                        HStack(spacing: 12) {
                            Label("\(recipe.cookingTime)m", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Label("\(recipe.servings)", systemImage: "person.2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Ingredients Section
                if !recipe.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundStyle(.orange)
                            Text("Ingredients")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(.orange)
                                        .fontWeight(.bold)
                                    Text(ingredient)
                                        .font(.body)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                
                // Instructions Section
                if !recipe.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.number")
                                .foregroundStyle(.green)
                            Text("Instructions")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                    
                                    Text(instruction)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                
                // Raw Generated Text (for debugging/development)
                if !recipe.generatedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.bubble")
                                .foregroundStyle(.purple)
                            Text("Generated Content")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(recipe.generatedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxHeight: 400)
        .clipped()
    }
}

#Preview {
    RecipeDisplayView(recipe: Recipe.sampleRecipes[0])
        .padding()
}