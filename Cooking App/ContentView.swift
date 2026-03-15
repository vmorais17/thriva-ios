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
    @State private var showingParameters = false
    @State private var errorMessage: String?
    @State private var parameters = GenerationParameters()
    @State private var ingredientInput = ""
    @State private var dietaryInput = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
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
                    generateRecipe(with: parameters)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        ingredientInput = parameters.ingredients.joinedWithCommas
                        dietaryInput = parameters.dietaryRestrictions.joinedWithCommas
                        showingParameters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                    }
                    .accessibilityLabel("Adjust generation settings")
                }
                
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
            .sheet(isPresented: $showingParameters) {
                NavigationStack {
                    Form {
                        Section("Category") {
                            Picker("Category", selection: Binding(get: { parameters.category }, set: { parameters.category = $0 })) {
                                Text("Any").tag(Optional<RecipeCategory>.none)
                                ForEach(RecipeCategory.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(Optional(category))
                                }
                            }
                        }
                        
                        Section("Difficulty") {
                            Picker("Difficulty", selection: Binding(get: { parameters.difficulty }, set: { parameters.difficulty = $0 })) {
                                Text("Any").tag(Optional<RecipeDifficulty>.none)
                                ForEach(RecipeDifficulty.allCases, id: \.self) { difficulty in
                                    Text(difficulty.rawValue).tag(Optional(difficulty))
                                }
                            }
                        }
                        
                        Section("Cooking Time (minutes)") {
                            Stepper(value: $parameters.cookingTime, in: 0...240, step: 5) {
                                Text(parameters.cookingTime == 0 ? "No preference" : "\(parameters.cookingTime) minutes")
                            }
                        }
                        
                        Section("Servings") {
                            Stepper(value: $parameters.servings, in: 1...12) {
                                Text("\(parameters.servings) serving(s)")
                            }
                        }
                        
                        Section("Ingredients") {
                            TextField("Comma separated", text: $ingredientInput.onChange { newValue in
                                parameters.ingredients = newValue
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                            })
                        }
                        
                        Section("Dietary Restrictions") {
                            TextField("Comma separated", text: $dietaryInput.onChange { newValue in
                                parameters.dietaryRestrictions = newValue
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                            })
                        }
                    }
                    .navigationTitle("Generation Settings")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Reset") {
                                parameters = GenerationParameters()
                                ingredientInput = ""
                                dietaryInput = ""
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingParameters = false
                            }
                        }
                    }
                }
            }
            .alert("Unable to generate recipe", isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented { errorMessage = nil }
                }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
        }
    }
    
    private func generateRecipe(with parameters: GenerationParameters) {
        isGenerating = true
        
        Task {
            do {
                let newRecipe = try await recipeGenerator.generateRecipe(with: parameters)
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentRecipe = newRecipe
                        isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
