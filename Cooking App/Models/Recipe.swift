//
//  Recipe.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import Foundation
import SwiftUI

struct Recipe: Identifiable, Codable {
    let id = UUID()
    let title: String
    let ingredients: [String]
    let instructions: [String]
    let cookingTime: Int // in minutes
    let servings: Int
    let category: RecipeCategory
    let difficulty: RecipeDifficulty
    let generatedText: String // Raw text from LLM
    let dateCreated: Date
    
    init(title: String = "", 
         ingredients: [String] = [], 
         instructions: [String] = [], 
         cookingTime: Int = 0, 
         servings: Int = 1, 
         category: RecipeCategory = .main, 
         difficulty: RecipeDifficulty = .easy,
         generatedText: String = "",
         dateCreated: Date = Date()) {
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.cookingTime = cookingTime
        self.servings = servings
        self.category = category
        self.difficulty = difficulty
        self.generatedText = generatedText
        self.dateCreated = dateCreated
    }
}

enum RecipeCategory: String, CaseIterable, Codable, Hashable {
    case appetizer = "Appetizer"
    case main = "Main Course"
    case dessert = "Dessert"
    case snack = "Snack"
    case beverage = "Beverage"
    case breakfast = "Breakfast"
    
    var systemImage: String {
        switch self {
        case .appetizer: return "leaf.circle"
        case .main: return "fork.knife.circle"
        case .dessert: return "birthday.cake"
        case .snack: return "popcorn.circle"
        case .beverage: return "cup.and.saucer"
        case .breakfast: return "sunrise"
        }
    }
}

enum RecipeDifficulty: String, CaseIterable, Codable, Hashable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .easy: return "1.circle"
        case .medium: return "2.circle"
        case .hard: return "3.circle"
        }
    }
}

// MARK: - Flexible Parsing
extension RecipeCategory {
    init?(flexible value: String?) {
        guard let value else { return nil }
        switch value.lowercased() {
        case "appetizer", "starter": self = .appetizer
        case "main", "main course", "entree": self = .main
        case "dessert", "sweet": self = .dessert
        case "snack": self = .snack
        case "beverage", "drink": self = .beverage
        case "breakfast", "brunch": self = .breakfast
        default: return nil
        }
    }
}

extension RecipeDifficulty {
    init?(flexible value: String?) {
        guard let value else { return nil }
        switch value.lowercased() {
        case "easy", "beginner", "simple": self = .easy
        case "medium", "moderate", "normal": self = .medium
        case "hard", "difficult", "advanced": self = .hard
        default: return nil
        }
    }
}

// MARK: - Sample Data for Development
extension Recipe {
    static let sampleRecipes: [Recipe] = [
        Recipe(
            title: "Classic Spaghetti Carbonara",
            ingredients: ["400g spaghetti", "200g pancetta", "4 large eggs", "100g Pecorino Romano", "Black pepper", "Salt"],
            instructions: ["Cook pasta in salted water", "Fry pancetta until crispy", "Whisk eggs with cheese", "Combine all ingredients off heat"],
            cookingTime: 25,
            servings: 4,
            category: .main,
            difficulty: .medium,
            generatedText: "A classic Italian pasta dish...",
            dateCreated: Date().addingTimeInterval(-86400)
        ),
        Recipe(
            title: "Chocolate Chip Cookies",
            ingredients: ["2¼ cups flour", "1 cup butter", "¾ cup brown sugar", "½ cup sugar", "2 eggs", "2 cups chocolate chips"],
            instructions: ["Cream butter and sugars", "Add eggs", "Mix in flour", "Fold in chocolate chips", "Bake at 375°F for 10 minutes"],
            cookingTime: 30,
            servings: 24,
            category: .dessert,
            difficulty: .easy,
            generatedText: "Delicious homemade cookies...",
            dateCreated: Date().addingTimeInterval(-172800)
        )
    ]
}
