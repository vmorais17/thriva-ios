# Cooking Assistant — On-Device LLM Inference on iOS

An iOS app that runs a fine-tuned language model entirely on-device to generate structured cooking recipes. No server, no API calls — inference happens locally using Google's MediaPipe Tasks GenAI SDK with a quantized Gemma 3 1B model.

---

## What makes this interesting

### On-device LLM inference

The app loads a ~1 GB INT8-quantized Gemma 3 1B model at launch and runs all generation locally via MediaPipe's `LlmInference` API. The model is bundled in the app's resources and copied to the Documents directory at first launch — this lets XNNPACK write a weight cache next to the model file, so subsequent launches mmap the pre-packed cache instead of repacking it from scratch (avoiding a multi-GB RAM spike that would OOM on device).

The inference path is fully async: `LlmInference` is initialized in a `Task.detached` block, model loading happens off the main thread, and `@Published` state updates are marshalled back via `@MainActor`. The UI never blocks.

### Text output → structured data

The model generates free-form recipe text. `RecipeParser` converts that into a typed `Recipe` struct by walking the output line by line — detecting section headers, list markers, time and serving metadata — without requiring the model to produce JSON. JSON parsing is kept as a fallback for structured outputs. The parser handles markdown formatting, numbered and bulleted lists, and intro sentences the model adds before the actual content.

### Model deployment pipeline

Getting a Gemma 3 model onto an iPhone means producing a single self-contained `.task` bundle: a MediaPipe artifact that packages the quantized model weights, SentencePiece tokenizer, and prompt metadata in one file that `LlmInference` can load directly.

**Fast path (used in this project):**

```
litert-community/Gemma3-1B-IT (HuggingFace)
    │  Pre-converted dynamic_int8 bundle, ekv1280 context, ~1 GB
    ▼
cooking_assistant_gemma3.task
    └──► Ready to add to Xcode target — no conversion tooling required
```

`litert-community` publishes pre-converted Gemma 3 1B IT `.task` files directly on HuggingFace. A single `hf_hub_download` call in Cell 0 of the conversion notebook retrieves `Gemma3-1B-IT_multi-prefill-seq_q8_ekv1280.task`, renames it to `cooking_assistant_gemma3.task`, and saves it to Drive.

**Alternative — build from source (if fast path fails):**

If the pre-converted bundle is unavailable, the full path (Cells 1–11) builds the `.task` from the raw HuggingFace checkpoint using two incompatible Colab sessions: a factory-reset runtime for `litert-torch` (PyTorch 2 export → quantized `.tflite`), then the main session for MediaPipe bundling (`.tflite` + tokenizer → `.task`). The two-session split exists because `litert-torch` and MediaPipe's bundler require conflicting TensorFlow/JAX stacks that cannot share a Python environment.

---

## Tech stack

| Layer | Technology |
|---|---|
| Language | Swift 6 |
| UI | SwiftUI (MVVM, declarative) |
| ML runtime | MediaPipe Tasks GenAI (`LlmInference`) |
| Model | Gemma 3 1B IT — DYNAMIC_INT8, ekv1280 |
| Concurrency | `async/await`, `@MainActor`, `Task.detached` |
| Dependencies | CocoaPods — `MediaPipeTasksGenAI`, `MediaPipeTasksGenAIC` |
| Tests | Swift Testing (`@Suite` / `@Test`) |
| Conversion | litert-torch 0.8.0, MediaPipe 0.10.21, HuggingFace `snapshot_download` |

---

## Architecture

```
Cooking App/
├── Models/
│   ├── Recipe.swift                  # Value type: UUID, category, difficulty, ingredients, steps
│   ├── RecipeGenerator.swift         # ViewModel: MediaPipe wiring, async inference, fallback path
│   ├── GenerationParameters.swift    # User config: dietary restrictions, cuisine, cook time
│   └── RecipeParser.swift            # Free-text → Recipe struct (section detection, metadata extraction)
├── Views/
│   ├── ContentView.swift             # Root: generate button, parameters sheet, history navigation
│   ├── RecipeDisplayView.swift       # Ingredients, numbered steps, cook time, servings
│   └── RecipeHistoryView.swift       # Paginated list, swipe-delete, clear-all
└── Utils/
    ├── Constants.swift               # AppConfig, SF Symbol refs, haptic wrappers, animation presets
    └── Extensions.swift              # Color palette, reusable view modifiers, String/Array helpers
```

**MVVM:** `RecipeGenerator` is an `ObservableObject` ViewModel. Views observe via `@StateObject` / `@ObservedObject`. Models are plain `struct` value types with no UIKit or SwiftUI imports.

**Concurrency:** `LlmInference` is initialized off the main thread in a `Task.detached` block. All `@Published` writes go through `MainActor.run`. The model is never touched from the main thread.

**Fallback:** When the model file is absent the app falls through to a simulated generation path. The Views have no knowledge of which path ran — no conditional compilation in the UI layer.

---

## Model conversion pipeline

The conversion notebook (`docs/gemma3_conversion.ipynb`) covers both paths. Cell 0 is the fast path — `hf_hub_download` from `litert-community/Gemma3-1B-IT`, validate the ZIP structure, done. Cells 1–11 are the full conversion path for building from source. Either path ends with Cell 11 saving `cooking_assistant_gemma3.task` to Google Drive and downloading it directly — the file is ready to drag into Xcode.

Key decisions made during development:

- **DYNAMIC_INT8 over INT4** — INT4 block quantization produced garbled output on device. INT8 is required for coherent generation at ~1 GB.
- **ekv1280 context window** — the pre-converted community model uses a 1280-token KV-cache. The litert-torch converter caps at 512 tokens; the community build removes that constraint with no practical downside for recipe-length outputs.
- **Prompt template newlines are load-bearing** — Gemma 3 uses `<start_of_turn>user\n...<end_of_turn>\n<start_of_turn>model\n`. Missing the `\n` after `user` causes the model to emit `<end_of_turn>` as its first token and produce zero output.
- **Documents/ cache invalidation** — iOS copies the bundle model to Documents/ on first launch so XNNPACK can write a weight cache alongside it. The app compares file sizes on each launch and re-copies if they differ, so replacing the `.task` in the bundle takes effect without deleting and reinstalling the app.
