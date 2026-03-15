//
//  RecipeParser.swift
//  Cooking App
//
//  Created by Codex on 11/10/24.
//

import Foundation

struct RecipeParser {
    private struct Payload: Decodable {
        let title: String?
        let ingredients: [String]?
        let instructions: [String]?
        let cookingTime: Int?
        let servings: Int?
        let category: String?
        let difficulty: String?
        let notes: String?
    }
    
    static func parseRecipeJSON(_ json: String, parameters: GenerationParameters? = nil) throws -> Recipe {
        guard let data = json.data(using: .utf8) else {
            throw RecipeError.parsingFailed
        }
        
        let decoder = JSONDecoder()
        let payload: Payload
        do {
            payload = try decoder.decode(Payload.self, from: data)
        } catch {
            throw RecipeError.parsingFailed
        }
        
        let title = payload.title?.trimmed ?? ""
        let ingredients = (payload.ingredients ?? []).map { $0.trimmed }.filter { !$0.isEmpty }
        let instructions = (payload.instructions ?? []).map { $0.trimmed }.filter { !$0.isEmpty }
        
        guard !title.isEmpty, !ingredients.isEmpty, !instructions.isEmpty else {
            throw RecipeError.parsingFailed
        }
        
        let category = RecipeCategory(flexible: payload.category) ?? parameters?.category ?? .main
        let difficulty = RecipeDifficulty(flexible: payload.difficulty) ?? parameters?.difficulty ?? .easy
        let cookingTime = payload.cookingTime ?? parameters?.cookingTime ?? 0
        let servings = payload.servings ?? parameters?.servings ?? 1
        
        var generatedText = json
        if let notes = payload.notes?.trimmed, !notes.isEmpty {
            generatedText += "\n\nNotes: \(notes)"
        }
        
        return Recipe(
            title: title,
            ingredients: ingredients,
            instructions: instructions,
            cookingTime: max(0, cookingTime),
            servings: max(1, servings),
            category: category,
            difficulty: difficulty,
            generatedText: generatedText,
            dateCreated: Date()
        )
    }
}
