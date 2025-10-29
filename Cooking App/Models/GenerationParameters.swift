//
//  GenerationParameters.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import Foundation

struct GenerationParameters {
    var category: RecipeCategory?
    var difficulty: RecipeDifficulty?
    var cookingTime: Int = 0 // 0 means no preference
    var servings: Int = 4
    var ingredients: [String] = []
    var dietaryRestrictions: [String] = []
    var cuisine: String = ""
    
    // Quick preset configurations
    static let quickMeal = GenerationParameters(
        difficulty: .easy,
        cookingTime: 30,
        servings: 2
    )
    
    static let familyDinner = GenerationParameters(
        category: .main,
        difficulty: .medium,
        servings: 6
    )
    
    static let dessertTreat = GenerationParameters(
        category: .dessert,
        difficulty: .easy,
        servings: 8
    )
    
    // Validation
    var isValid: Bool {
        cookingTime >= 0 && servings > 0
    }
}

// Dietary restriction options
extension GenerationParameters {
    static let commonDietaryRestrictions = [
        "vegetarian",
        "vegan", 
        "gluten-free",
        "dairy-free",
        "low-carb",
        "keto",
        "paleo",
        "low-sodium"
    ]
    
    static let popularCuisines = [
        "Italian",
        "Mexican", 
        "Asian",
        "Mediterranean",
        "Indian",
        "French",
        "American",
        "Thai",
        "Japanese",
        "Greek"
    ]
}