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
internal import MediaPipeTasksGenAI
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
    
    // Copy model from read-only app bundle to writable Documents directory.
    // This allows XNNPACK to write its weight cache next to the model file,
    // so subsequent launches mmap the pre-packed cache instead of repacking
    // the full model in RAM (avoids the ~5 GB peak that OOMs on device).
    private func writableModelPath(fileName: String, fileExt: String) async throws -> String {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent("\(fileName).\(fileExt)")
        guard let src = Bundle.main.url(forResource: fileName, withExtension: fileExt) else {
            throw RecipeError.modelNotFound
        }
        // Re-copy if destination is missing or size differs (model was updated in bundle)
        let destSize = (try? fm.attributesOfItem(atPath: dest.path)[.size] as? Int) ?? 0
        let srcSize  = (try? fm.attributesOfItem(atPath: src.path)[.size] as? Int) ?? -1
        if destSize != srcSize {
            try? fm.removeItem(at: dest)
            try fm.copyItem(at: src, to: dest)
        }
        return dest.path
    }

    private func setupModel() {
        // Prevent multiple concurrent setup attempts
        guard !isSettingUpModel else {
            print("[LLM] setupModel() skipped — already in progress")
            return
        }
        isSettingUpModel = true
        // Capture statics on the calling context before entering the detached task
        let modelFileName  = AppConfig.modelFileName
        let modelFileExt   = AppConfig.modelFileExtension
        let maxTokens      = AppConfig.maxTokens
        let defaultTopK    = AppConfig.defaultTopK
        print("[LLM] setupModel() started — looking for '\(modelFileName).\(modelFileExt)'")

        #if canImport(MediaPipeTasksGenAI)
        Task.detached { [weak self] in
            guard let self else { return }

            let modelPath: String
            do {
                modelPath = try await self.writableModelPath(fileName: modelFileName, fileExt: modelFileExt)
                print("[LLM] Model path resolved: \(modelPath)")
            } catch {
                print("[LLM] Model file not found in bundle: \(error)")
                await MainActor.run {
                    self.lastError = ErrorMessages.modelNotFound
                    self.isSettingUpModel = false
                }
                return
            }

            do {
                print("[LLM] Initialising LlmInference (may take 10–60 s)...")
                let options = LlmInference.Options(modelPath: modelPath)
                // maxTokens must not exceed the model's KV-cache size (ekv1280 → 1280)
                options.maxTokens = maxTokens
                options.maxTopk   = defaultTopK
                print("[LLM] Options: maxTokens=\(options.maxTokens) maxTopk=\(options.maxTopk)")

                let inference = try LlmInference(options: options)

                await MainActor.run {
                    self.llmInference = inference
                    self.modelLoaded = true
                    self.isSettingUpModel = false
                }
                print("[LLM] Model setup complete ✓")
            } catch {
                print("[LLM] LlmInference init failed: \(error)")
                await MainActor.run {
                    self.lastError = ErrorMessages.modelLoadFailed + " (\(error.localizedDescription))"
                    self.isSettingUpModel = false
                }
            }
        }
        #else
        print("[LLM] MediaPipeTasksGenAI not available — simulation mode")
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
        } catch RecipeError.parsingFailed {
            // LLM produced non-JSON output — log and fall through to simulation
            print("LLM response could not be parsed as JSON — falling back to simulated recipe")
        } catch {
            lastError = error.localizedDescription
            throw error
        }

        // Fallback: simulated recipe when LLM is unavailable or output is unparseable
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let simulatedRecipe = generateSimulatedRecipe(parameters: parameters)
        generatedRecipes.insert(simulatedRecipe, at: 0)
        lastError = nil
        
        return simulatedRecipe
    }
    
    // Build prompt from parameters — plain text, matches the LoRA training format
    private func buildJSONPrompt(from parameters: GenerationParameters) -> String {
        var parts: [String] = []

        if let category = parameters.category { parts.append(category.rawValue.lowercased()) }
        if let difficulty = parameters.difficulty { parts.append(difficulty.rawValue.lowercased()) }
        if !parameters.cuisine.isEmpty { parts.append(parameters.cuisine) }
        if !parameters.dietaryRestrictions.isEmpty { parts.append(contentsOf: parameters.dietaryRestrictions) }
        if !parameters.ingredients.isEmpty { parts.append("using \(parameters.ingredients.joined(separator: ", "))") }
        if parameters.cookingTime > 0 { parts.append("ready in \(parameters.cookingTime) minutes") }

        // Mirror Cell 5 training test: "Give me a simple pasta recipe"
        // No period — LoRA training likely didn't use punctuation at end of prompts
        var dishType = ""
        if let category = parameters.category {
            switch category {
            case .breakfast: dishType = "breakfast"
            case .main:     dishType = "main"
            case .beverage:    dishType = "beverage"
            case .snack:     dishType = "snack"
            case .dessert:   dishType = "dessert"
            default:         dishType = "main course"
            }
        }
        let cuisinePart = parameters.cuisine.isEmpty ? "" : " \(parameters.cuisine)"
        let ingPart     = parameters.ingredients.isEmpty ? "" : " with \(parameters.ingredients.prefix(3).joined(separator: ", "))"
        let baseDish    = dishType.isEmpty ? "recipe" : "\(dishType) recipe"
        return "Give me a simple\(cuisinePart) \(baseDish)\(ingPart)"
    }
    
    private func generateUsingLLM(parameters: GenerationParameters) async throws -> Recipe? {
        #if canImport(MediaPipeTasksGenAI)
        guard canUseLLM, let llmInference else {
            return nil
        }
        
        let prompt = buildJSONPrompt(from: parameters)
        print("=== LLM PROMPT ===\n\(prompt)\n=== END PROMPT ===")
        let response = try await llmInference.generateResponse(inputText: prompt)
        print("=== LLM RAW RESPONSE (\(response.count) chars) ===")
        print(response)
        print("=== END RESPONSE ===")
        return try RecipeParser.parse(response, parameters: parameters)
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
    case modelNotFound
    case noResponse
    case generationFailed
    case invalidInput
    case generationInProgress
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Recipe model could not be loaded"
        case .modelNotFound:
            return ErrorMessages.modelNotFound
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
