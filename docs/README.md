# Recipe Generator — iOS On-Device LLM App

## App Status: Architecturally Complete

The app is fully functional with a simulated generation path. All Swift/SwiftUI/MediaPipe wiring is done. The only remaining step is adding the converted `cooking_assistant.task` model file to the Xcode bundle.

---

## Quick Start

1. Open `Cooking App.xcworkspace` (not `.xcodeproj`)
2. Run on iPhone 16 Pro simulator or a real device (iOS 16.0+)
3. Tap **Generate Recipe** — runs a 2-second simulation until the model file is bundled
4. View results, browse history, swipe to delete

---

## Model Pipeline — Why So Many Conversion Steps?

The fine-tuned model is published on Kaggle as `cooking_assistant_lora_4_epoch10.lora.h5`. Getting from that file to a model running on an iPhone requires four distinct format conversions. Each one crosses a hard runtime boundary — none can be skipped.

### The Source: Kaggle LoRA Checkpoint

The Kaggle model card describes it as:

> *"This fine-tuned model is an instruction-oriented cooking assistant… Leveraging LoRA significantly reduced the computational overhead while still enabling effective domain adaptation."*

LoRA (Low-Rank Adaptation) is a training technique. Instead of fine-tuning all 2 billion parameters of Gemma 2B, it trains two small low-rank adapter matrices per layer — producing a ~50 MB delta file instead of a ~5 GB full checkpoint. This is ideal for publishing and versioning training work cheaply.

The `.lora.h5` is a **training artifact**, not a deployment artifact. The Kaggle author's job was to prove the fine-tuning worked. Getting it onto a phone is the app developer's job — which is exactly this pipeline.

---

### The Four Formats

```
cooking_assistant_lora_4_epoch10.lora.h5
        │
        │  Cannot run: partial delta only, base model not included.
        │  Must load base Gemma 2B from Kaggle and merge LoRA weights.
        ▼
HuggingFace Safetensors  (model.safetensors — 4.9 GB)
        │
        │  Universal, framework-neutral checkpoint.
        │  Still a Python/server format — not an inference graph.
        │  Must compile to a mobile-optimized binary.
        ▼
LiteRT / TFLite  (.tflite)
        │
        │  Mobile-optimized flat binary with KV-cache optimization.
        │  Still a raw model file — no tokenizer, no inference metadata.
        │  Must bundle everything MediaPipe needs to run it.
        ▼
MediaPipe Task Bundle  (cooking_assistant.task)
        │
        │  Self-contained deployment artifact:
        │  LiteRT model + tokenizer + inference metadata.
        └──► Ready to load on iOS via MediaPipeTasksGenAI SDK.
```

| Format | What it is | Who uses it |
|---|---|---|
| `.lora.h5` | Keras LoRA delta weights (training artifact) | KerasNLP / training pipelines |
| `.safetensors` | Framework-neutral full checkpoint | HuggingFace ecosystem, any Python ML tooling |
| `.tflite` / LiteRT | Compiled, quantized mobile inference graph | TFLite runtime, ai-edge-litert |
| `.task` | MediaPipe deployment bundle (model + tokenizer + metadata) | MediaPipe Tasks GenAI SDK on iOS/Android |

---

### Current Conversion State

| Artifact | Location | Status |
|---|---|---|
| LoRA weights | `thriva/cooking_assistant_lora_4_epoch10.lora.h5` | ✅ Present |
| HuggingFace export (288/288 weights) | `thriva/final_export/hf_export/model.safetensors` | ✅ 4.9 GB, intact |
| Colab upload package | `thriva/final_export/hf_model_for_colab.zip` | ✅ 3.8 GB, ready to upload |
| `cooking_assistant.task` | `thriva/mediapipe_output/cooking_assistant.task` | ❌ Sparse file — 0 bytes allocated, conversion incomplete |

Local conversion was blocked by missing native libraries (`libpywrap_litert_common.dylib`) and protobuf version conflicts on macOS. The solution is Google Colab, which has all dependencies pre-installed. See `mediapipe_output/COLAB_CONVERSION_GUIDE.md` for the step-by-step workflow (~15 minutes).

---

### Completing the Pipeline (Colab)

1. Upload `final_export/hf_model_for_colab.zip` (3.8 GB) to Google Colab
2. Run the conversion notebook — HuggingFace → LiteRT → `.task`
3. Download `cooking_assistant.task` (~1–2 GB)
4. Add the file to the Xcode target (drag into project navigator, check "Add to target")
5. Build and run — `RecipeGenerator.setupModel()` will load it automatically

No Swift changes are needed. The MediaPipe integration is already wired and was updated to match the 0.10.24 SDK API.

---

## Project Structure

```
Cooking App/
├── Models/
│   ├── Recipe.swift                  # Core data model (UUID, category, difficulty, dietary)
│   ├── RecipeGenerator.swift         # LLM ViewModel (@MainActor, MediaPipe 0.10.24 wired)
│   ├── GenerationParameters.swift    # User-configurable generation config
│   └── RecipeParser.swift            # JSON → Recipe struct parser with error recovery
├── Views/
│   ├── ContentView.swift             # Root view: generate button, parameters, history nav
│   ├── RecipeDisplayView.swift       # Recipe presentation (title, metadata, ingredients, steps)
│   └── RecipeHistoryView.swift       # Paginated list with swipe-delete and clear-all
├── Utils/
│   ├── Constants.swift               # AppConfig, UserDefaults keys, SF Symbols, haptics
│   └── Extensions.swift              # Color palette, view modifiers, String/Array helpers
└── Cooking_AppApp.swift              # App entry point

Cooking App Tests/
├── Cooking_App_Tests.swift           # 9 suites: architecture, parameters, error, concurrency
├── RecipeParserTests.swift           # JSON parsing validation
└── MediaPipeIntegrationTests.swift   # Phase 2–3 integration tests (.disabled until model bundled)
```

---

## Architecture

**Pattern:** MVVM — `RecipeGenerator` is the ViewModel (`ObservableObject`), Views observe via `@StateObject`/`@ObservedObject`, Models are plain `struct` value types.

**Concurrency:** All inference runs in a `Task.detached` block. `@MainActor` isolation ensures `@Published` state updates never touch background threads.

**Fallback:** When `cooking_assistant.task` is absent, `generateRecipe()` automatically falls through to `simulateGeneration()`. The UI is identical — no conditional compilation in views.

---

## MediaPipe Integration (Already Wired)

```swift
// RecipeGenerator.swift — setupModel() — MediaPipe 0.10.24
#if canImport(MediaPipeTasksGenAI)
let options = LlmInference.Options(modelPath: modelPath)
options.maxTokens = AppConfig.maxTokens       // 512
options.temperature = AppConfig.defaultTemperature  // 0.8
options.topK = AppConfig.defaultTopK          // 40
let inference = try LlmInference(options: options)
#endif

// generateUsingLLM() — async/await, no callback wrapper
let response = try await llmInference.generateResponse(inputText: prompt)
```

Model path resolves via `Bundle.main.path(forResource: AppConfig.modelFileName, ofType: AppConfig.modelFileExtension)` — `"cooking_assistant"` + `"task"`.

---

## Running Tests

```bash
xcodebuild test \
  -workspace "Cooking App.xcworkspace" \
  -scheme "Cooking App" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

---

## Known Issues Resolved

| Issue | Fix |
|---|---|
| `chef.hat.fill` SF Symbol not found | Replaced with `fork.knife.circle.fill` in `Constants.swift` |
| Asset catalog `'green'` color error | `RecipeDifficulty.color` returns `Color` values directly, not strings |
| Core Analytics simulator warning | Harmless simulator noise, no fix needed |
| `LlmInferenceOptions` / `baseOptions.modelPath` API mismatch | Updated to `LlmInference.Options(modelPath:)` for SDK 0.10.24 |
| Callback-style `generateResponse` wrapper | Replaced with direct `try await llmInference.generateResponse(inputText:)` |
