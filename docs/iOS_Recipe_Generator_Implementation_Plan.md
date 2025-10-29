# iOS Recipe Generator App - Implementation Plan
## Using Gemma2 2B Fine-Tuned Model with MediaPipe

---

## Executive Summary

This document outlines a minimalist iOS app implementation that generates random recipes using your fine-tuned Gemma2 2B model (`cooking_assistant_lora_4_epoch10_lora.h5`) through MediaPipe's LLM Inference API. The scope is restricted to create a simple proof-of-concept with a single button interface, while remaining open to future extensions.

---

## 1. Project Overview

### 1.1 Core Features (MVP)
- **Single Button UI**: "Generate Recipe" button centered on screen
- **On-Device Inference**: Uses MediaPipe LLM Inference API with your fine-tuned model
- **Recipe Display**: Shows generated recipe text in scrollable view
- **Loading State**: Activity indicator during generation

### 1.2 Technology Stack
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **ML Framework**: MediaPipe Tasks GenAI (iOS)
- **Model**: Gemma2 2B with LoRA fine-tuning
- **Minimum iOS Version**: iOS 16.0+
- **Development Tool**: Xcode 15+

---

## 2. Prerequisites & Setup

### 2.1 Development Environment
```bash
# Required installations:
- macOS Ventura (13.0) or later
- Xcode 15 or later
- CocoaPods 1.12.1+

# Install CocoaPods if needed:
sudo gem install cocoapods
```

### 2.2 Model Preparation

Your model file needs conversion to MediaPipe format:

#### Step 1: Install MediaPipe Python Package
```bash
pip install mediapipe --break-system-packages
```

#### Step 2: Convert LoRA Model to MediaPipe Format
```python
import mediapipe as mp
from mediapipe.tasks.python.genai import converter

# Configuration for Gemma2 2B with LoRA
config = converter.ConversionConfig(
    # Base model configuration
    model_name="gemma2-2b",
    backend="gpu",  # Required for LoRA inference
    
    # LoRA-specific configuration
    lora_rank=4,  # Based on your filename
    lora_checkpoint_path="cooking_assistant_lora_4_epoch10_lora.h5",
    base_model_path="path/to/base/gemma2-2b-model",  # Download from HuggingFace
)

# Convert to MediaPipe format
converter.convert(config, output_path="cooking_assistant.task")
```

**Note**: The `.task` file is what you'll include in your iOS app bundle.

---

## 3. iOS App Architecture

### 3.1 Project Structure
```
RecipeGenerator/
├── RecipeGeneratorApp.swift       # App entry point
├── Views/
│   ├── ContentView.swift          # Main UI
│   └── RecipeDisplayView.swift    # Recipe output display
├── Models/
│   ├── RecipeGenerator.swift      # LLM inference wrapper
│   └── Recipe.swift                # Data model
├── Resources/
│   └── cooking_assistant.task      # Your converted model
└── Info.plist
```

### 3.2 Key Components

#### A. App Entry Point
```swift
// RecipeGeneratorApp.swift
import SwiftUI

@main
struct RecipeGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### B. Main View (Minimalist UI)
```swift
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var recipeGenerator = RecipeGenerator()
    @State private var isGenerating = false
    @State private var generatedRecipe = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Title
                Text("Random Recipe Generator")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Generate Button
                Button {
                    generateRecipe()
                } label: {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Generate Recipe")
                            .font(.headline)
                    }
                }
                .frame(width: 200, height: 60)
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(30)
                .disabled(isGenerating)
                
                // Recipe Display
                if !generatedRecipe.isEmpty {
                    RecipeDisplayView(recipe: generatedRecipe)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Recipe AI")
        }
    }
    
    private func generateRecipe() {
        isGenerating = true
        
        Task {
            do {
                generatedRecipe = try await recipeGenerator.generateRandomRecipe()
                isGenerating = false
            } catch {
                print("Error generating recipe: \(error)")
                generatedRecipe = "Failed to generate recipe. Please try again."
                isGenerating = false
            }
        }
    }
}
```

#### C. Recipe Display Component
```swift
// RecipeDisplayView.swift
import SwiftUI

struct RecipeDisplayView: View {
    let recipe: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Recipe:")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(recipe)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .frame(maxHeight: 400)
    }
}
```

#### D. LLM Inference Manager
```swift
// RecipeGenerator.swift
import Foundation
import MediaPipeTasksGenAI

@MainActor
class RecipeGenerator: ObservableObject {
    private var llmInference: LlmInference?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        guard let modelPath = Bundle.main.path(
            forResource: "cooking_assistant",
            ofType: "task"
        ) else {
            print("Model file not found")
            return
        }
        
        let options = LlmInferenceOptions()
        options.baseOptions.modelPath = modelPath
        options.maxTokens = 512
        options.temperature = 0.8
        options.topK = 40
        options.randomSeed = Int(Date().timeIntervalSince1970)
        
        do {
            llmInference = try LlmInference(options: options)
            print("Model loaded successfully")
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    func generateRandomRecipe() async throws -> String {
        guard let llmInference = llmInference else {
            throw RecipeError.modelNotLoaded
        }
        
        // Random prompts to generate variety
        let prompts = [
            "Generate a random recipe with ingredients and instructions.",
            "Create a unique dinner recipe for tonight.",
            "Suggest a healthy recipe with step-by-step instructions.",
            "Generate a creative recipe using common ingredients.",
            "Create a recipe for a delicious meal."
        ]
        
        let selectedPrompt = prompts.randomElement() ?? prompts[0]
        
        return try await withCheckedThrowingContinuation { continuation in
            llmInference.generateResponse(inputText: selectedPrompt) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: RecipeError.noResponse)
                }
            }
        }
    }
}

enum RecipeError: Error {
    case modelNotLoaded
    case noResponse
}
```

---

## 4. Step-by-Step Implementation

### Step 1: Create Xcode Project
1. Open Xcode → Create New Project
2. Select **iOS → App**
3. Product Name: `RecipeGenerator`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. Click **Next** and save

### Step 2: Setup CocoaPods
Create `Podfile` in project root:
```ruby
platform :ios, '16.0'

target 'RecipeGenerator' do
  use_frameworks!
  
  # MediaPipe GenAI library for LLM inference
  pod 'MediaPipeTasksGenAI'
  pod 'MediaPipeTasksGenAIC'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
```

Install dependencies:
```bash
cd RecipeGenerator
pod install
```

**Important**: From now on, open `RecipeGenerator.xcworkspace` instead of `.xcodeproj`

### Step 3: Add Model File
1. Convert your `.h5` model to `.task` format (see Section 2.2)
2. In Xcode, drag `cooking_assistant.task` into project
3. Ensure **"Copy items if needed"** is checked
4. Confirm **"RecipeGenerator" target** is selected

### Step 4: Implement Code Files
1. Create the files outlined in Section 3.2
2. Copy the code from each section
3. Build the project (⌘+B) to check for errors

### Step 5: Configure Info.plist
No special permissions needed for basic functionality.

### Step 6: Test on Simulator/Device
1. Select simulator or connected device
2. Click Run (⌘+R)
3. Tap "Generate Recipe" button
4. View generated recipe output

---

## 5. Configuration Options

### 5.1 LLM Parameters (Adjustable in `RecipeGenerator.swift`)

```swift
options.maxTokens = 512        // Maximum response length
options.temperature = 0.8      // Creativity (0.0-1.0)
options.topK = 40              // Sampling diversity
options.randomSeed = Int(...)  // For reproducibility
```

**Tuning Recommendations**:
- **Higher temperature (0.9-1.0)**: More creative/random recipes
- **Lower temperature (0.5-0.7)**: More focused/traditional recipes
- **maxTokens**: Increase for longer recipes (up to 1024)

### 5.2 Prompt Engineering

Customize prompts in `generateRandomRecipe()` for different recipe types:

```swift
let prompts = [
    "Generate a quick 15-minute recipe.",
    "Create a vegetarian dinner recipe.",
    "Suggest a low-carb meal with instructions.",
    "Generate a dessert recipe using chocolate.",
]
```

---

## 6. Extension Points (Future Development)

### 6.1 Immediate Extensions
- [ ] Add recipe history (save previous generations)
- [ ] Category selection (dessert, main course, appetizer)
- [ ] Dietary filter options (vegetarian, vegan, gluten-free)
- [ ] Share recipe feature
- [ ] Save favorite recipes

### 6.2 Advanced Features
- [ ] Ingredient input customization
- [ ] Image generation for recipes (using separate model)
- [ ] Nutritional information calculation
- [ ] Shopping list creation
- [ ] Voice input for recipe requests
- [ ] Multi-language support

### 6.3 UI Enhancements
- [ ] Dark mode optimization
- [ ] Custom animations
- [ ] Recipe card design
- [ ] Ingredient icons
- [ ] Step-by-step cooking mode

---

## 7. Troubleshooting

### Common Issues & Solutions

#### Model Not Loading
```swift
// Check console for:
"Model file not found"

// Solution: Verify model is in Bundle
if Bundle.main.path(forResource: "cooking_assistant", ofType: "task") == nil {
    print("Model missing from bundle!")
}
```

#### Memory Issues
```swift
// For large models, ensure:
options.maxTokens = 256  // Reduce for lower memory usage
```

#### Slow Generation
- Use GPU backend (already configured in conversion)
- Reduce `maxTokens` value
- Test on actual device (simulators are slower)

#### CocoaPods Issues
```bash
# Clean and reinstall
pod deintegrate
pod install

# Update CocoaPods
sudo gem install cocoapods
```

---

## 8. Performance Optimization

### 8.1 Model Loading
```swift
// Load model once during init, not per-request
class RecipeGenerator: ObservableObject {
    private var llmInference: LlmInference?
    
    init() {
        setupModel()  // Load immediately
    }
}
```

### 8.2 Async/Await Best Practices
```swift
// Always use Task for async operations
Task {
    let recipe = try await recipeGenerator.generateRandomRecipe()
}
```

### 8.3 Memory Management
- Model stays in memory during app lifecycle
- Releases when app terminates
- For production, consider lazy loading

---

## 9. Testing Strategy

### 9.1 Unit Tests
```swift
// RecipeGeneratorTests.swift
import XCTest
@testable import RecipeGenerator

class RecipeGeneratorTests: XCTestCase {
    func testModelInitialization() {
        let generator = RecipeGenerator()
        XCTAssertNotNil(generator)
    }
    
    func testRecipeGeneration() async throws {
        let generator = RecipeGenerator()
        let recipe = try await generator.generateRandomRecipe()
        XCTAssertFalse(recipe.isEmpty)
    }
}
```

### 9.2 Manual Testing Checklist
- [ ] Button tap generates recipe
- [ ] Loading indicator appears during generation
- [ ] Recipe text displays correctly
- [ ] Multiple generations work consecutively
- [ ] App doesn't crash on rapid taps
- [ ] Memory usage stays reasonable

---

## 10. Deployment Considerations

### 10.1 Model Size
- Gemma2 2B model: ~2-4 GB compressed
- Total app size: ~2.5-4.5 GB
- Consider TestFlight for beta testing

### 10.2 App Store Guidelines
- Comply with App Store Review Guidelines
- Mention AI-generated content in description
- Include privacy policy (if collecting data)

### 10.3 Device Compatibility
- **Minimum**: iPhone 12 or later
- **Recommended**: iPhone 14 Pro or later
- **RAM**: 4GB+ required for smooth operation

---

## 11. Code Organization Best Practices

### 11.1 MVVM Architecture
```
View (SwiftUI) → ViewModel (ObservableObject) → Model (LLM)
```

### 11.2 Error Handling
```swift
enum RecipeError: Error, LocalizedError {
    case modelNotLoaded
    case noResponse
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Recipe model could not be loaded"
        case .noResponse:
            return "No recipe was generated"
        case .generationFailed:
            return "Failed to generate recipe"
        }
    }
}
```

### 11.3 Logging
```swift
import os

private let logger = Logger(
    subsystem: "com.yourapp.recipegenerator",
    category: "RecipeGeneration"
)

logger.info("Generating recipe with prompt: \(prompt)")
```

---

## 12. Quick Reference Commands

### Build Commands
```bash
# Clean build
xcodebuild clean -workspace RecipeGenerator.xcworkspace -scheme RecipeGenerator

# Build for simulator
xcodebuild -workspace RecipeGenerator.xcworkspace -scheme RecipeGenerator -sdk iphonesimulator

# Build for device
xcodebuild -workspace RecipeGenerator.xcworkspace -scheme RecipeGenerator -sdk iphoneos
```

### CocoaPods Commands
```bash
pod install          # Install dependencies
pod update           # Update all pods
pod deintegrate      # Remove CocoaPods from project
pod repo update      # Update CocoaPods repository
```

---

## 13. Resources & References

### Official Documentation
- [MediaPipe LLM Inference iOS Guide](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/ios)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift.org SwiftUI Tutorial](https://www.swift.org/getting-started/swiftui/)

### Model Resources
- [Gemma Models on HuggingFace](https://huggingface.co/google/gemma-2b)
- [MediaPipe Model Conversion Guide](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference#model-conversion)
- [LoRA Fine-tuning Guide](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/ios#lora-tuning)

### Community
- [MediaPipe GitHub](https://github.com/google-ai-edge/mediapipe)
- [MediaPipe iOS Examples](https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/llm_inference/ios)

---

## 14. Next Steps

### Immediate Actions (Week 1)
1. ✅ Setup development environment
2. ✅ Convert model to MediaPipe format
3. ✅ Create Xcode project with CocoaPods
4. ✅ Implement basic UI
5. ✅ Test recipe generation

### Short-term Goals (Weeks 2-4)
1. Add recipe history feature
2. Implement dietary filters
3. Polish UI/UX design
4. Add error handling
5. TestFlight beta testing

### Long-term Vision (Months 2-3)
1. Advanced customization options
2. Recipe image generation
3. Social sharing features
4. App Store submission
5. User feedback iteration

---

## Conclusion

This implementation plan provides a solid foundation for building a minimalist iOS recipe generator app using your fine-tuned Gemma2 2B model with MediaPipe. The architecture is designed to be simple yet extensible, allowing you to quickly create a proof-of-concept while maintaining the flexibility to add advanced features later.

**Key Advantages**:
- ✅ On-device processing (privacy-friendly)
- ✅ No internet required after download
- ✅ Fast inference with GPU acceleration
- ✅ Clean, maintainable code structure
- ✅ Easy to extend with new features

**Estimated Development Time**: 2-4 hours for basic PoC

Start with the MVP, test thoroughly, and gradually add features based on user feedback. Good luck with your project! 🚀👨‍🍳
