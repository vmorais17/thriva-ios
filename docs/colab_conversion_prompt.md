# Prompt: Complete MediaPipe Conversion in Google Colab

Use this file as a ready-to-paste prompt for an AI assistant (Claude, ChatGPT, Gemini) inside a Google Colab session, or follow it manually cell by cell.

---

## Context

A Gemma 2B model was fine-tuned with LoRA on a cooking recipe dataset and exported through a multi-step pipeline:

```
cooking_assistant_lora_4_epoch10.lora.h5   (Keras LoRA delta, training artifact)
        ↓  merged with base Gemma 2B weights
model.safetensors   (HuggingFace export, 288/288 weights mapped, 4.9 GB)
        ↓  NEXT STEP — this is what needs to be done
cooking_assistant.task   (MediaPipe deployment bundle for iOS — MISSING)
```

The HuggingFace export is complete and verified. The `.task` file does not yet exist (a prior local attempt produced a 0-byte sparse file due to missing macOS native libraries). All remaining work must run in Google Colab (T4 GPU recommended).

The upload package is ready at:
```
/Users/viniciusmorais/Desktop/thriva/final_export/hf_model_for_colab.zip  (3.8 GB)
```

Contents of the zip:
- `model.safetensors` — 4.9 GB, all 288 weights mapped from KerasNLP
- `config.json` — Gemma 2B architecture config
- `generation_config.json`
- `tokenizer.model` — SentencePiece tokenizer (4.0 MB)
- `tokenizer_config.json` — 46 KB

---

## Goal

Produce `cooking_assistant.task` — a MediaPipe Task bundle containing:
1. The LiteRT (TFLite) model with KV-cache optimization
2. The SentencePiece tokenizer
3. Gemma chat prompt format metadata (`<start_of_turn>` / `<end_of_turn>`)

Target runtime: **MediaPipe Tasks GenAI 0.10.24** on iOS (iPhone, `MediaPipeTasksGenAI` CocoaPod).

---

## Instructions for the Colab Session

### Cell 1 — Install dependencies

```python
!pip install ai-edge-torch mediapipe transformers torch
```

### Cell 2 — Upload and unzip the model

```python
from google.colab import files
import os, zipfile

os.makedirs("/content/hf_model", exist_ok=True)

print("Upload hf_model_for_colab.zip when prompted:")
uploaded = files.upload()

zip_name = list(uploaded.keys())[0]
with zipfile.ZipFile(f"/content/{zip_name}", "r") as z:
    z.extractall("/content/hf_model")

print("Contents:", os.listdir("/content/hf_model"))
```

### Cell 3 — Convert HuggingFace → LiteRT

```python
from ai_edge_torch.generative.examples.gemma import gemma
from ai_edge_torch.generative.utilities import converter
from ai_edge_torch.generative.utilities.export_config import ExportConfig
from ai_edge_torch.generative.layers import kv_cache

print("Loading model from HuggingFace checkpoint…")
pytorch_model = gemma.build_model_from_hf_checkpoint(
    "/content/hf_model",
    "gemma2_2b"
)

export_config = ExportConfig()
export_config.kvcache_layout = kv_cache.KV_LAYOUT_TRANSPOSED
export_config.mask_as_input = True

os.makedirs("/content/litert_output", exist_ok=True)

print("Converting to LiteRT — expect 5–10 minutes…")
converter.convert_to_tflite(
    pytorch_model,
    output_path="/content/litert_output",
    output_name_prefix="cooking_assistant",
    prefill_seq_len=512,
    kv_cache_max_len=2048,
    quantize="dynamic_int8",
    export_config=export_config,
)

print("LiteRT output:")
!ls -lh /content/litert_output/
```

> **If `gemma.build_model_from_hf_checkpoint` raises an error**, use the fallback in Cell 3B below before proceeding to Cell 4.

### Cell 3B — Fallback: generic ai-edge-torch conversion (only if Cell 3 fails)

```python
from transformers import AutoModelForCausalLM
import torch, ai_edge_torch

model = AutoModelForCausalLM.from_pretrained(
    "/content/hf_model",
    local_files_only=True,
    torch_dtype=torch.float32
)
model.eval()

os.makedirs("/content/litert_output", exist_ok=True)
sample_input = torch.randint(0, 256000, (1, 10))

edge_model = ai_edge_torch.convert(model, (sample_input,))
edge_model.export("/content/litert_output/cooking_assistant.tflite")

print("Fallback LiteRT output:")
!ls -lh /content/litert_output/
```

> Note: the fallback does not include KV-cache optimisation, so on-device inference will be slower.

### Cell 4 — Bundle LiteRT + tokenizer → `.task`

```python
from mediapipe.tasks.python.genai import bundler

print("Bundling .task file…")

config = bundler.BundleConfig(
    tflite_model="/content/litert_output/cooking_assistant.tflite",
    tokenizer_model="/content/hf_model/tokenizer.model",
    start_token="<bos>",
    stop_tokens=["<eos>", "<end_of_turn>"],
    output_filename="/content/cooking_assistant.task",
    prompt_prefix="<start_of_turn>user\n",
    prompt_suffix="<end_of_turn>\n<start_of_turn>model\n",
    model_name="Cooking Assistant",
    model_description="Gemma-2-2B fine-tuned for cooking recipes"
)

bundler.create_bundle(config)

size_mb = os.path.getsize("/content/cooking_assistant.task") / (1024 * 1024)
print(f"Done. File size: {size_mb:.0f} MB")
```

### Cell 5 — Download

```python
from google.colab import files
files.download("/content/cooking_assistant.task")
```

---

## After Download — Add to iOS App

1. **Replace the sparse placeholder:**
   ```bash
   # Delete the hollow file
   rm /Users/viniciusmorais/Desktop/thriva/mediapipe_output/cooking_assistant.task
   # Move the real file here
   mv ~/Downloads/cooking_assistant.task \
      /Users/viniciusmorais/Desktop/thriva/mediapipe_output/
   ```

2. **Add to the Xcode target:**
   - Open `Cooking App.xcworkspace`
   - Drag `cooking_assistant.task` into the project navigator
   - In the dialog: check **"Add to target: Cooking App"**, select **"Copy items if needed"**
   - Confirm it appears under **Build Phases → Copy Bundle Resources**

3. **Build and run** — no Swift changes needed. `RecipeGenerator.setupModel()` resolves the model path via:
   ```
   Bundle.main.path(forResource: "cooking_assistant", ofType: "task")
   ```
   When found, `modelLoaded` becomes `true` and `generateRecipe()` uses the real LLM instead of the simulation.

4. **Verify with a test prompt:**
   ```
   me de uma receita de bolinho de bacalhau com aimpim
   ```
   Expected: a structured JSON response that `RecipeParser` deserialises into a `Recipe` — Portuguese codfish fritters with cassava.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Upload times out (3.8 GB) | Slow connection or free Colab disk limit | Upload files individually; `model.safetensors` (4.9 GB) may require Colab Pro |
| `gemma.build_model_from_hf_checkpoint` import error | `ai-edge-torch` version mismatch | Use Cell 3B fallback |
| `bundler.BundleConfig` attribute error | mediapipe version mismatch | Run `!pip install mediapipe==0.10.14` and restart runtime |
| `.task` loads but generates gibberish | Tokenizer or prompt format mismatch | Confirm `start_token`, `stop_tokens`, `prompt_prefix`/`suffix` match Gemma 2 chat template |
| App still uses simulation after adding file | File not in Copy Bundle Resources | Check Build Phases → Copy Bundle Resources in Xcode |

---

## Success Criteria

- [ ] `cooking_assistant.task` downloads from Colab and is > 500 MB
- [ ] File added to Xcode bundle; Build Phases shows it under Copy Bundle Resources
- [ ] App builds and runs without errors
- [ ] `modelLoaded == true` visible in debug output (`"MediaPipe model setup complete"`)
- [ ] Recipe is generated (not simulated) within ~10–30 seconds on device
