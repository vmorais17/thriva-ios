//
//  Constants.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import Foundation
import SwiftUI

// MARK: - App Configuration
struct AppConfig {
    static let appName = "Recipe Generator"
    static let version = "1.0.0"
    static let minimumIOSVersion = "16.0"
    
    // MediaPipe Model Configuration
    static let modelFileName = "cooking_assistant_v3"
    static let modelFileExtension = "task"
    static let maxTokens = 512
    static let defaultTemperature: Float = 0.8
    static let defaultTopK = 40
    
    // UI Configuration
    static let animationDuration: Double = 0.3
    static let buttonCornerRadius: CGFloat = 25
    static let cardCornerRadius: CGFloat = 12
    static let defaultPadding: CGFloat = 16
}

// MARK: - User Defaults Keys
struct UserDefaultsKeys {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let preferredDifficulty = "preferredDifficulty"
    static let preferredCategory = "preferredCategory"
    static let generationHistory = "generationHistory"
    static let favoriteRecipes = "favoriteRecipes"
}

// MARK: - System Images
struct SystemImages {
    static let generate = "wand.and.stars"
    static let history = "clock"
    static let settings = "gearshape"
    static let share = "square.and.arrow.up"
    static let favorite = "heart"
    static let favoriteFilled = "heart.fill"
    static let delete = "trash"
    static let refresh = "arrow.clockwise"
    static let chef = "chef.hat.fill"
    static let cooking = "fork.knife.circle"
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}

// MARK: - Animation Presets
struct AnimationPresets {
    static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let easeInOut = Animation.easeInOut(duration: AppConfig.animationDuration)
    static let bouncy = Animation.interpolatingSpring(stiffness: 300, damping: 15)
    static let quick = Animation.easeInOut(duration: 0.2)
}

// MARK: - Recipe Generation Prompts
struct RecipePrompts {
    static let base = [
        "Generate a detailed recipe with ingredients and step-by-step instructions.",
        "Create a unique recipe with creative ingredients and clear cooking steps.",
        "Suggest a delicious recipe with ingredient quantities and preparation method.",
        "Generate an original recipe with full ingredient list and cooking directions.",
        "Create a tasty recipe including ingredients, instructions, and cooking tips."
    ]
    
    static let quick = [
        "Generate a quick 15-minute recipe that's easy to make.",
        "Create a simple recipe perfect for busy weeknights.",
        "Suggest a fast recipe with minimal ingredients and steps."
    ]
    
    static let healthy = [
        "Generate a healthy, nutritious recipe with fresh ingredients.",
        "Create a balanced recipe that's both delicious and wholesome.",
        "Suggest a recipe that's good for you and tastes amazing."
    ]
    
    static let comfort = [
        "Generate a comfort food recipe that's warm and satisfying.",
        "Create a cozy recipe perfect for a relaxing evening.",
        "Suggest a hearty recipe that feels like a warm hug."
    ]
}

// MARK: - Error Messages
struct ErrorMessages {
    nonisolated(unsafe) static let modelNotFound = "Recipe model could not be found. Please reinstall the app."
    nonisolated(unsafe) static let modelLoadFailed = "Failed to load the recipe model. Please try again."
    nonisolated(unsafe) static let generationFailed = "Could not generate a recipe. Please try again."
    nonisolated(unsafe) static let noInternet = "This app works offline, no internet connection needed!"
    nonisolated(unsafe) static let genericError = "Something went wrong. Please try again."
}

// MARK: - Success Messages
struct SuccessMessages {
    static let recipeGenerated = "Recipe generated successfully!"
    static let recipeSaved = "Recipe saved to your collection!"
    static let recipeShared = "Recipe shared successfully!"
    static let historyCleared = "Recipe history cleared!"
}
