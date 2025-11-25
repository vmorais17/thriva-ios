//
//  TestValidation.swift
//  Cooking App Tests
//
//  Created by Vinicius Morais on 10/29/25.
//

import Testing
import XCTest
import Foundation
@testable import Cooking_App

@Suite("Basic Test Validation")
struct BasicTestValidation {
    
    @Test("Basic App Structure Test")
    func basicAppStructureTest() async throws {
        // This is the most basic test to verify imports work
        
        // Test that we can create a RecipeGenerator
        let generator = RecipeGenerator()
        #expect(generator != nil, "Should be able to create RecipeGenerator")
        
        // Test that we can create GenerationParameters
        let params = GenerationParameters()
        #expect(params.isValid, "Default parameters should be valid")
        
        print("✅ Basic app structure is working")
    }
    
    @Test("Simple Recipe Generation Test")  
    func simpleRecipeGenerationTest() async throws {
        // Test the most basic recipe generation without complex actor interactions
        
        let generator = RecipeGenerator()
        let params = GenerationParameters.quickMeal
        
        let startTime = Date()
        let recipe = try await generator.generateRecipe(with: params)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(!recipe.title.isEmpty, "Recipe should have title")
        #expect(duration > 1.0, "Should take at least 1 second (simulation)")
        #expect(duration < 5.0, "Should complete within 5 seconds")
        
        print("✅ Basic recipe generation working: '\(recipe.title)'")
        print("📊 Generation took: \(String(format: "%.2f", duration)) seconds")
    }
    
    @Test("Error Types Test")
    func errorTypesTest() async throws {
        // Test that error types work correctly
        
        let error1 = RecipeError.modelNotLoaded
        let error2 = RecipeError.noResponse
        let error3 = RecipeError.generationFailed
        
        #expect(!error1.localizedDescription.isEmpty, "Error 1 should have description")
        #expect(!error2.localizedDescription.isEmpty, "Error 2 should have description") 
        #expect(!error3.localizedDescription.isEmpty, "Error 3 should have description")
        
        print("✅ Error handling types working")
    }
}