//
//  RecipeGenerator.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import Foundation
import SwiftUI
internal import Combine
#if canImport(MediaPipeTasksGenAI)
import MediaPipeTasksGenAI
#endif

// This will be the main LLM interface - prepared for MediaPipe integration
class RecipeGenerator: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var generatedRecipes: [Recipe] = []
    
    // Model configuration (ready for MediaPipe integration)
    private var modelLoaded = false
    private var isSettingUpModel = false
    
    #if canImport(MediaPipeTasksGenAI)
    private var llmInference: LlmInference?
    #endif
    
    private var canUseLLM: Bool {
        #if canImport(MediaPipeTasksGenAI)
        return modelLoaded && llmInference != nil
        #else
        return false
        #endif
    }
    
    init() {
        setupModel()
        // Safely load sample recipes on main actor
        Task { @MainActor [weak self] in
            self?.loadSampleRecipes()
        }
    }
    
    private func setupModel() {
        // Prevent multiple concurrent setup attempts
        guard !isSettingUpModel else { return }
        isSettingUpModel = true
        
        #if canImport(MediaPipeTasksGenAI)
        Task.detached { [weak self] in
            guard let self else { return }
            
            guard let modelPath = Bundle.main.path(
                forResource: AppConfig.modelFileName,
                ofType: AppConfig.modelFileExtension
            ) else {
                await MainActor.run {
                    self.lastError = ErrorMessages.modelNotFound
                    self.isSettingUpModel = false
                }
                return
            }
            
            do {
                let options = LlmInference.Options(modelPath: modelPath)
                options.maxTokens = AppConfig.maxTokens
                options.temperature = AppConfig.defaultTemperature
                options.topK = AppConfig.defaultTopK

                let inference = try LlmInference(options: options)
                
                await MainActor.run {
                    self.llmInference = inference
                    self.modelLoaded = true
                    self.isSettingUpModel = false
                }
                print("MediaPipe model setup complete")
            } catch {
                await MainActor.run {
                    self.lastError = ErrorMessages.modelLoadFailed + " (\(error.localizedDescription))"
                    self.isSettingUpModel = false
                }
            }
        }
        #else
        // MediaPipe frameworks not available in this build; keep simulation path
        modelLoaded = false
        isSettingUpModel = false
        #endif
    }
    
    // Main recipe generation function - ready for LLM integration
    @MainActor
    func generateRecipe(with parameters: GenerationParameters = GenerationParameters()) async throws -> Recipe {
        guard parameters.isValid else {
            lastError = RecipeError.invalidInput.localizedDescription
            throw RecipeError.invalidInput
        }
        // Prevent multiple concurrent generations
        guard !isLoading else {
            throw RecipeError.generationInProgress
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let recipe = try await generateUsingLLM(parameters: parameters) {
                lastError = nil
                generatedRecipes.insert(recipe, at: 0)
                return recipe
            }
        } catch {
            lastError = error.localizedDescription
            throw error
        }
        
        // Simulate LLM generation when real model is unavailable
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let simulatedRecipe = generateSimulatedRecipe(parameters: parameters)
        generatedRecipes.insert(simulatedRecipe, at: 0)
        lastError = nil
        
        return simulatedRecipe
    }
    
    // Build prompt from parameters (JSON-focused)
    private func buildJSONPrompt(from parameters: GenerationParameters) -> String {
        var requirements: [String] = []
        
        if let category = parameters.category {
            requirements.append("Category: \(category.rawValue)")
        }
        if let difficulty = parameters.difficulty {
            requirements.append("Difficulty: \(difficulty.rawValue)")
        }
        if parameters.cookingTime > 0 {
            requirements.append("Cooking time about \(parameters.cookingTime) minutes")
        }
        requirements.append("Servings: \(parameters.servings)")
        if !parameters.ingredients.isEmpty {
            requirements.append("Use ingredients: \(parameters.ingredients.joined(separator: ", "))")
        }
        if !parameters.dietaryRestrictions.isEmpty {
            requirements.append("Dietary preferences: \(parameters.dietaryRestrictions.joined(separator: ", "))")
        }
        if !parameters.cuisine.isEmpty {
            requirements.append("Cuisine: \(parameters.cuisine)")
        }
        
        let schema = """
        {
          "title": "String",
          "ingredients": ["String", "String"],
          "instructions": ["String", "String"],
          "cookingTime": 30,
          "servings": 4,
          "category": "Main Course",
          "difficulty": "Medium",
          "notes": "Optional tips"
        }
        """
        
        return """
        You are an expert chef. Return ONLY valid JSON following this schema, with no explanations or markdown:
        \(schema)
        Rules:
        - Include at least 4 ingredients and 3 instructions.
        - Use integers for cookingTime (minutes) and servings.
        - category should be a human label (e.g., Main Course, Dessert, Snack, Beverage).
        - difficulty should be Easy, Medium, or Hard.
        Context: \(requirements.joined(separator: "; "))
        Output must be strict JSON that can be decoded without changes.
        """
    }
    
    private func generateUsingLLM(parameters: GenerationParameters) async throws -> Recipe? {
        #if canImport(MediaPipeTasksGenAI)
        guard canUseLLM, let llmInference else {
            return nil
        }
        
        let prompt = buildJSONPrompt(from: parameters)
        let response = try await llmInference.generateResponse(inputText: prompt)
        
        return try RecipeParser.parseRecipeJSON(response, parameters: parameters)
        #else
        return nil
        #endif
    }
    
    // Generate sample recipes for testing UI
    private func generateSimulatedRecipe(parameters: GenerationParameters) -> Recipe {
        let titles = [
            "Garlic Butter Shrimp", "Veggie Stir Fry", "Chocolate Lava Cake",
            "Chicken Tikka Masala", "Greek Salad", "Beef Tacos",
            "Mushroom Risotto", "Apple Pie", "Thai Green Curry"
        ]
        
        let baseIngredients = [
            ["olive oil", "garlic", "salt", "pepper"],
            ["onion", "herbs", "spices"],
            ["flour", "butter", "eggs"]
        ]
        
        let randomTitle = titles.randomElement() ?? "Mystery Recipe"
        let randomIngredients = baseIngredients.randomElement() ?? ["ingredients"]
        let randomInstructions = [
            "Prepare ingredients",
            "Heat pan over medium heat",
            "Cook according to recipe",
            "Serve and enjoy"
        ]
        
        return Recipe(
            title: randomTitle,
            ingredients: randomIngredients,
            instructions: randomInstructions,
            cookingTime: Int.random(in: 15...60),
            servings: Int.random(in: 2...6),
            category: parameters.category ?? RecipeCategory.allCases.randomElement()!,
            difficulty: parameters.difficulty ?? RecipeDifficulty.allCases.randomElement()!,
            generatedText: "Simulated recipe text for \(randomTitle)...",
            dateCreated: Date()
        )
    }
    
    @MainActor
    private func loadSampleRecipes() {
        generatedRecipes = Recipe.sampleRecipes
    }
    
    // Helper functions for UI
    @MainActor
    func clearHistory() {
        generatedRecipes.removeAll()
    }
    
    @MainActor
    func deleteRecipe(_ recipe: Recipe) {
        generatedRecipes.removeAll { $0.id == recipe.id }
    }
}

// Error handling for LLM operations
enum RecipeError: Error, LocalizedError {
    case modelNotLoaded
    case noResponse
    case generationFailed
    case invalidInput
    case generationInProgress
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Recipe model could not be loaded"
        case .noResponse:
            return "No recipe was generated"
        case .generationFailed:
            return "Failed to generate recipe"
        case .invalidInput:
            return "Invalid input parameters"
        case .generationInProgress:
            return "Recipe generation already in progress"
        case .parsingFailed:
            return "Generated recipe could not be parsed"
        }
    }
}
