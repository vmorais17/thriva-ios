//
//  ContentView.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var recipeGenerator = RecipeGenerator()
    @State private var isGenerating = false
    @State private var currentRecipe: Recipe?
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text("Recipe Generator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("AI-powered culinary creativity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Main Generation Button
                Button {
                    generateRecipe()
                } label: {
                    HStack(spacing: 12) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                            
                            Text("Generate Recipe")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                .disabled(isGenerating)
                .scaleEffect(isGenerating ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isGenerating)
                .accessibilityIdentifier("generateRecipeButton")
                .accessibilityLabel(isGenerating ? "Generating Recipe" : "Generate Recipe")
                .accessibilityHint("Tap to generate a new recipe using AI")
                
                // Recipe Display Section
                if let recipe = currentRecipe {
                    RecipeDisplayView(recipe: recipe)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else if !isGenerating {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text("Tap the button above to generate your first recipe!")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .opacity(0.7)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Recipe AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock")
                            .font(.title3)
                    }
                    .disabled(recipeGenerator.generatedRecipes.isEmpty)
                }
            }
            .sheet(isPresented: $showingHistory) {
                RecipeHistoryView()
                    .environmentObject(recipeGenerator)
            }
        }
    }
    
    private func generateRecipe() {
        isGenerating = true
        
        Task {
            do {
                let newRecipe = try await recipeGenerator.generateRecipe()
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentRecipe = newRecipe
                        isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    // TODO: Show error alert
                    print("Error generating recipe: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
