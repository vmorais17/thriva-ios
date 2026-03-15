//
//  RecipeParserTests.swift
//  Cooking App Tests
//
//  Created by Codex on 11/10/24.
//

import Testing
@testable import Cooking_App

@Suite("Recipe JSON Parsing")
struct RecipeJSONParsingTests {
    
    @Test("Parses valid JSON into Recipe")
    func parsesValidJSON() throws {
        let json = """
        {
          "title": "Herb Pasta",
          "ingredients": ["pasta", "olive oil", "garlic", "basil"],
          "instructions": ["Boil pasta", "Saute garlic", "Combine with herbs"],
          "cookingTime": 20,
          "servings": 2,
          "category": "Main Course",
          "difficulty": "Easy"
        }
        """
        
        let recipe = try RecipeParser.parseRecipeJSON(json)
        
        #expect(recipe.title == "Herb Pasta")
        #expect(recipe.ingredients.count == 4)
        #expect(recipe.instructions.count == 3)
        #expect(recipe.cookingTime == 20)
        #expect(recipe.servings == 2)
        #expect(recipe.category == .main)
        #expect(recipe.difficulty == .easy)
    }
    
    @Test("Rejects invalid JSON payloads")
    func rejectsInvalidJSON() throws {
        // Missing instructions should fail
        let json = """
        {
          "title": "Incomplete",
          "ingredients": ["item"]
        }
        """
        
        #expect(throws: RecipeError.parsingFailed) {
            _ = try RecipeParser.parseRecipeJSON(json)
        }
    }
}
