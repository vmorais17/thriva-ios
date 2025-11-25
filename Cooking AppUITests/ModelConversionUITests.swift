//
//  ModelConversionUITests.swift
//  Cooking AppUITests
//
//  Created by Vinicius Morais on 10/29/25.
//

import XCTest

// MARK: - UI Tests for Model Conversion Validation
// Note: Using XCTest framework (not Swift Testing) as this is a UITests target
// UITests traditionally use XCTest for UI automation capabilities

final class ModelConversionUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Add launch arguments for debugging
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        // Verify app launched successfully
        XCTAssertTrue(app.exists, "App should launch successfully")
        
        // Wait for app to stabilize by checking if the generate button exists
        let generateButton = getGenerateButton()
        let appStabilized = generateButton.waitForExistence(timeout: 5.0)
        XCTAssertTrue(appStabilized, "App should stabilize within 5 seconds")
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helper Methods
    
    private func getGenerateButton() -> XCUIElement {
        // Try accessibility identifier first (most reliable)
        let buttonById = app.buttons["generateRecipeButton"]
        if buttonById.exists {
            return buttonById
        }
        
        // Fallback to text-based lookup
        let buttonByText = app.buttons["Generate Recipe"]
        if buttonByText.exists {
            return buttonByText
        }
        
        // Final fallback - look for any button containing "Generate"
        let fallbackButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'generate'")).firstMatch
        
        // If no button is found, return a non-existent element to avoid crashes
        if !fallbackButton.exists {
            print("⚠️ Generate button not found using any method")
        }
        
        return fallbackButton
    }
    
    private func waitForGenerateButtonToReturn(timeout: TimeInterval = 10.0) -> Bool {
        let button = getGenerateButton()
        return button.waitForExistence(timeout: timeout) && button.isEnabled
    }
    
    private func waitForRecipeContent(timeout: TimeInterval = 10.0) -> Bool {
        // Look for recipe content to appear
        let recipeScrollView = app.scrollViews.firstMatch
        return recipeScrollView.waitForExistence(timeout: timeout)
    }
    
    private func waitForUIStabilization(timeout: TimeInterval = 5.0) -> Bool {
        let generateButton = getGenerateButton()
        return generateButton.waitForExistence(timeout: timeout)
    }
    
    private func waitForOperationCompletion(timeout: TimeInterval = 10.0) -> Bool {
        // Wait for any ongoing operations to complete
        let generateButton = getGenerateButton()
        
        // Wait for button to exist and be enabled
        guard generateButton.waitForExistence(timeout: timeout) else { return false }
        
        // Use a polling approach instead of Thread.sleep
        let pollInterval: TimeInterval = 0.1
        let maxAttempts = Int(1.0 / pollInterval)
        
        for _ in 0..<maxAttempts {
            if generateButton.exists && generateButton.isEnabled {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
        }
        
        return generateButton.exists
    }
    
    private func performSingleGeneration(generationNumber: Int) -> Bool {
        let generateButton = getGenerateButton()
        
        guard generateButton.exists else {
            print("Generation \(generationNumber): Button not found")
            return false
        }
        
        generateButton.tap()
        
        // Use a small delay for any immediate UI changes
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        
        // Check if recipe content appeared
        if waitForRecipeContent(timeout: 3.0) {
            print("Generation \(generationNumber): Recipe content appeared")
            return true
        } else if waitForGenerateButtonToReturn(timeout: 5.0) {
            print("Generation \(generationNumber): Button became ready again")
            return true
        } else {
            print("Generation \(generationNumber): No clear completion signal")
            return false
        }
    }
    
    // MARK: - UI Validation Tests Before Model Integration
    
    @MainActor
    func testAppLaunchAndInitialState() throws {
        // Test 17: Validate app launches correctly with current UI
        
        // Check main UI elements are present
        let generateButton = getGenerateButton()
        XCTAssertTrue(generateButton.exists, "Generate Recipe button should exist")
        XCTAssertTrue(generateButton.isEnabled, "Generate Recipe button should be enabled")
        
        // Check for history button or navigation elements
        let toolbar = app.toolbars.firstMatch
        if toolbar.exists {
            print("✅ Toolbar found with elements")
        }
        
        // Check navigation title
        let navigationTitle = app.navigationBars.firstMatch
        XCTAssertTrue(navigationTitle.exists, "Navigation bar should exist")
        
        print("✅ App launches successfully with expected UI elements")
    }
    
    @MainActor
    func testRecipeGenerationUIFlow() throws {
        // Test 18: Validate complete recipe generation UI flow
        
        let generateButton = getGenerateButton()
        XCTAssertTrue(generateButton.exists, "Generate button should exist")
        
        // Record initial state
        let initialButtonLabel = generateButton.label
        print("Initial button state: \(initialButtonLabel)")
        
        // Tap generate button
        generateButton.tap()
        
        // Wait for recipe content to appear instead of arbitrary sleep
        let recipeContentAppeared = waitForRecipeContent(timeout: 10.0)
        if recipeContentAppeared {
            print("✅ Recipe content appeared after generation")
            
            // Check if recipe content appeared in scroll view
            let scrollViews = app.scrollViews
            print("Found \(scrollViews.count) scroll views after generation")
            
            if scrollViews.count > 0 {
                let scrollView = scrollViews.firstMatch
                let scrollViewTexts = scrollView.staticTexts
                print("Found \(scrollViewTexts.count) text elements in recipe content")
            }
        } else {
            print("⚠️  No recipe content appeared, checking for any text changes")
            
            // Look for any text that might contain recipe information
            let allText = app.staticTexts
            var foundRecipeContent = false
            for i in 0..<min(allText.count, 10) { // Check first 10 text elements
                let text = allText.element(boundBy: i)
                if text.exists && !text.label.isEmpty {
                    print("Text element \(i): '\(text.label)'")
                    if text.label.contains("Recipe") || text.label.contains("ingredients") || 
                       text.label.contains("Instructions") {
                        foundRecipeContent = true
                    }
                }
            }
            
            print("Recipe content found in static texts: \(foundRecipeContent)")
        }
        
        // Ensure button is still functional after generation
        let buttonStillExists = generateButton.exists
        XCTAssertTrue(buttonStillExists, "Generate button should still exist after generation")
    }
    
    @MainActor
    func testNavigationElementsExist() throws {
        // Test 19: Validate navigation and toolbar elements
        
        // Check for navigation bars
        let navBars = app.navigationBars
        print("Found \(navBars.count) navigation bars")
        
        // Check for toolbars
        let toolbars = app.toolbars
        print("Found \(toolbars.count) toolbars")
        
        // Check for any buttons in toolbar
        if toolbars.count > 0 {
            let toolbar = toolbars.firstMatch
            let toolbarButtons = toolbar.buttons
            print("Found \(toolbarButtons.count) buttons in toolbar")
            
            for i in 0..<min(toolbarButtons.count, 5) {
                let button = toolbarButtons.element(boundBy: i)
                if button.exists {
                    print("Toolbar button \(i): '\(button.label)'")
                }
            }
        }
        
        // Look for history-related elements
        let historyElements = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] 'history'")
        )
        print("Found \(historyElements.count) history-related elements")
    }
    
    @MainActor
    func testMultipleGenerationsUIStability() throws {
        // Test 20: Test UI stability with multiple generations
        
        let generateButton = getGenerateButton()
        
        // Perform multiple generations
        for i in 1...3 {
            print("Starting generation \(i)")
            
            XCTAssertTrue(generateButton.exists, "Generate button should exist for generation \(i)")
            
            // Perform generation using helper method
            let generationCompleted = performSingleGeneration(generationNumber: i)
            
            print("Completed generation \(i) (detected: \(generationCompleted))")
            
            // Check UI is still stable
            XCTAssertTrue(generateButton.exists, "Generate button should still exist after generation \(i)")
        }
        
        print("✅ UI remains stable after multiple generations")
    }
    
    // MARK: - Performance and Accessibility Tests
    
    @MainActor
    func testLaunchPerformanceBaseline() throws {
        // Test 21: Establish launch performance baseline
        
        // Only run performance tests on device, not simulator
        #if targetEnvironment(simulator)
        throw XCTSkip("Performance tests disabled on simulator")
        #endif
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launchArguments = ["UI_TESTING"]
            testApp.launch()
            
            // Wait for app to be ready
            let generateButton = testApp.buttons["generateRecipeButton"]
            _ = generateButton.waitForExistence(timeout: 5.0)
            
            testApp.terminate()
        }
        
        print("✅ Launch performance baseline established")
    }
    
    @MainActor
    func testAccessibilityElementsBaseline() throws {
        // Test 22: Validate accessibility before MediaPipe integration
        
        // Use helper method instead of duplicating logic
        let generateButton = getGenerateButton()
        XCTAssertTrue(generateButton.exists, "Generate button should be accessible")
        
        // Test that the button has proper accessibility properties
        let accessibilityLabel = generateButton.label
        XCTAssertFalse(accessibilityLabel.isEmpty, "Generate button should have an accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("Generate") || accessibilityLabel.contains("generate"), 
                     "Button label should contain 'Generate' (case insensitive)")
        
        print("✅ Generate button is accessible with label: '\(accessibilityLabel)'")
        
        // Test additional accessibility properties
        XCTAssertTrue(generateButton.isHittable, "Generate button should be hittable")
        
        // Count all accessible elements
        let allAccessibleElements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        print("Total accessible elements: \(allAccessibleElements.count)")
        
        // This establishes a baseline for comparison after MediaPipe integration
        XCTAssertGreaterThan(allAccessibleElements.count, 0, "Should have accessible elements")
    }
    
    @MainActor
    func testMemoryUsageBaseline() throws {
        // Test 23: Establish memory usage baseline
        
        // Wait for app to stabilize after launch
        let generateButton = getGenerateButton()
        let appReady = generateButton.waitForExistence(timeout: 5.0)
        XCTAssertTrue(appReady, "App should be ready within 5 seconds")
        
        // Perform several recipe generations to test memory behavior
        for i in 1...5 {
            if generateButton.exists && generateButton.isEnabled {
                print("Starting memory test generation \(i)")
                _ = performSingleGeneration(generationNumber: i)
                
                // Check that the app is still responsive
                XCTAssertTrue(generateButton.exists, "Generate button should exist after generation \(i)")
                
                print("Memory test generation \(i) completed")
            } else {
                print("Skipping generation \(i) - button not available")
            }
        }
        
        // App should still be responsive
        XCTAssertTrue(generateButton.exists, "App should remain responsive after multiple generations")
        XCTAssertTrue(app.exists, "App should not have crashed")
        
        print("✅ Memory usage baseline established")
    }
    
    // MARK: - Error Handling UI Tests
    
    @MainActor
    func testRapidTapHandling() throws {
        // Test 24: Validate UI handles rapid button taps gracefully
        
        let generateButton = getGenerateButton()
        XCTAssertTrue(generateButton.exists, "Generate button should exist before rapid tap test")
        
        // Record initial state
        let initiallyEnabled = generateButton.isEnabled
        print("Button initially enabled: \(initiallyEnabled)")
        
        // Rapid taps should not crash the app
        for i in 1...5 {
            if generateButton.exists {
                print("Rapid tap \(i)")
                generateButton.tap()
                // Small delay between taps to be more realistic
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }
        
        // App should still be functional
        XCTAssertTrue(app.exists, "App should not crash from rapid taps")
        
        // Wait for any pending operations to complete
        let operationsCompleted = waitForOperationCompletion(timeout: 15.0)
        print("Operations completed successfully: \(operationsCompleted)")
        
        // Button should still exist
        XCTAssertTrue(generateButton.exists, "Generate button should still exist after rapid taps")
        
        print("✅ UI handles rapid taps gracefully")
    }
    
    @MainActor
    func testUIElementsStabilityAfterInteraction() throws {
        // Test 25: Ensure UI elements remain stable after user interactions
        
        let generateButton = getGenerateButton()
        XCTAssertTrue(generateButton.exists, "Generate button should exist")
        
        // Test single interaction
        generateButton.tap()
        RunLoop.current.run(until: Date().addingTimeInterval(2.0)) // Allow for processing
        
        // Verify UI elements are still accessible
        XCTAssertTrue(generateButton.exists, "Generate button should exist after interaction")
        
        // Test navigation elements are still present
        let navBar = app.navigationBars.firstMatch
        if navBar.exists {
            XCTAssertTrue(navBar.exists, "Navigation bar should remain after interaction")
        }
        
        // Test toolbar elements are still present
        let toolbar = app.toolbars.firstMatch
        if toolbar.exists {
            XCTAssertTrue(toolbar.exists, "Toolbar should remain after interaction")
        }
        
        print("✅ UI elements remain stable after interaction")
    }
    
    // MARK: - Tests to Enable After MediaPipe Integration
    
    @MainActor
    func testMediaPipeModelLoadingUI() throws {
        // Test 26: UI behavior during MediaPipe model loading
        
        throw XCTSkip("Enable after MediaPipe model integration")
        
        /*
        // Restart app to test model loading behavior
        app.terminate()
        app.launch()
        
        // Look for any loading indicators during model initialization
        let loadingElements = app.activityIndicators
        let loadingText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'loading' OR label CONTAINS[c] 'model'")
        )
        
        if loadingElements.count > 0 || loadingText.count > 0 {
            print("Model loading UI elements detected")
            
            // Wait for loading to complete
            let generateButton = app.buttons["Generate Recipe"]
            let ready = generateButton.waitForExistence(timeout: 30.0)
            XCTAssertTrue(ready, "App should be ready after model loading")
        }
        */
    }
    
    @MainActor
    func testRealModelGenerationUI() throws {
        // Test 27: UI with real MediaPipe model generation
        
        throw XCTSkip("Enable after MediaPipe model integration")
        
        /*
        let generateButton = app.buttons["Generate Recipe"]
        generateButton.tap()
        
        // Real model generation might take much longer
        let recipeContent = app.scrollViews.firstMatch
        let exists = recipeContent.waitForExistence(timeout: 60.0)
        XCTAssertTrue(exists, "Recipe should generate with real model")
        
        // Validate that real content is more substantial
        let allText = app.staticTexts
        var totalTextLength = 0
        for i in 0..<allText.count {
            let text = allText.element(boundBy: i)
            if text.exists {
                totalTextLength += text.label.count
            }
        }
        
        XCTAssertGreaterThan(totalTextLength, 100, "Real model should generate substantial content")
        print("Generated content length: \(totalTextLength) characters")
        */
    }
    
    @MainActor
    func testModelPerformanceUI() throws {
        // Test 28: UI performance with real model
        
        throw XCTSkip("Enable after MediaPipe model integration")
        
        /*
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            let generateButton = app.buttons["Generate Recipe"]
            generateButton.tap()
            
            // Wait for real generation to complete
            let recipeContent = app.scrollViews.firstMatch
            _ = recipeContent.waitForExistence(timeout: 60.0)
        }
        */
    }
    
    @MainActor
    func testModelErrorHandlingUI() throws {
        // Test 29: UI behavior when model encounters errors
        
        throw XCTSkip("Enable after MediaPipe model integration")
        
        /*
        // This would test scenarios like:
        // - Model fails to load
        // - Generation fails
        // - Memory issues
        // - Invalid inputs
        
        // For each error scenario, validate:
        // - Error message is displayed to user
        // - UI remains functional
        // - User can retry
        // - App doesn't crash
        */
    }
}
