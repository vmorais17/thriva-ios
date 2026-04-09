# Testing cooking_assistant.task Model

## Status: ✅ Model Ready (5 GB)

Your `cooking_assistant.task` file is now present and properly sized (~5 GB). The MediaPipe integration tests have been **enabled** and are ready to run!

---

## Quick Test Commands

### Run All Tests (Phase 1 + MediaPipe Tests)

```bash
cd "/path/to/Cooking App"

# Open the workspace
open "Cooking App.xcworkspace"

# Run all tests via Xcode
# Press ⌘+U in Xcode
```

**Or via command line:**

```bash
xcodebuild test \
  -workspace "Cooking App.xcworkspace" \
  -scheme "Cooking App" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

---

## What Tests Are Now Enabled

### ✅ Phase 1: Architecture Tests (9 tests)
These validate your app architecture and establish baselines:
1. Source Model File Validation
2. Bundle Structure Validation
3. MediaPipe Dependencies Check
4. RecipeGenerator Architecture Validation
5. Generation Parameters Validation
6. Error Handling Architecture
7. Memory Usage Baseline
8. Generation Performance Baseline
9. Concurrent Generation Handling

### ✅ Phase 2-3: MediaPipe Integration Tests (7 tests - NOW ENABLED)
These validate the actual model functionality:
10. **Model File Validation** - Checks file size (should be ~5 GB)
11. **MediaPipe Framework Loading** - Validates framework loads correctly
12. **Model Loading and Initialization** - Tests model loading (may take 10-30 seconds)
13. **Real Model Inference** - Tests actual recipe generation
14. **Prompt Engineering Validation** - Tests different recipe types (quick meal, family dinner, dessert)
15. **Model Performance Benchmarking** - Measures generation time (3 iterations)
16. **Error Recovery and Resilience** - Tests error handling and recovery

---

## Expected Test Results

### Test 10: Model File Validation
**Expected:**
```
✅ Model file validated: ~5000 MB
```

### Test 11: MediaPipe Framework Loading
**Expected:**
```
✅ MediaPipe framework loaded successfully
✅ Model path: /path/to/cooking_assistant.task
```

### Test 12: Model Loading and Initialization
**Expected:**
```
⏳ Loading MediaPipe model (this may take 10-30 seconds)...
✅ MediaPipe model loaded successfully in X.XX seconds
```

**Note:** First load may be slow, subsequent loads should be faster.

### Test 13: Real Model Inference
**Expected:**
```
⏳ Waiting for model initialization...
⏳ Generating recipe with real MediaPipe model...
✅ Real recipe generated in X.XX seconds
📜 Title: [Recipe Name]
🥘 Ingredients: [Count]
📋 Instructions: [Count]
```

**Performance Target:**
- ✅ Optimal: < 30 seconds
- ⚠️ Acceptable: 30-60 seconds
- ❌ Too slow: > 60 seconds

### Test 14: Prompt Engineering Validation
**Expected:**
```
⏳ Testing quick meal generation...
✅ Quick meal recipe: [Recipe Name]
⏳ Testing family dinner generation...
✅ Family dinner recipe: [Recipe Name]
⏳ Testing dessert generation...
✅ Dessert recipe: [Recipe Name]
```

### Test 15: Model Performance Benchmarking
**Expected:**
```
⏳ Performance test iteration 1/3...
   Duration: X.XX s
⏳ Performance test iteration 2/3...
   Duration: X.XX s
⏳ Performance test iteration 3/3...
   Duration: X.XX s

📊 MediaPipe Performance:
  Average generation time: X.XX s
  Minimum generation time: X.XX s
  Maximum generation time: X.XX s
```

### Test 16: Error Recovery and Resilience
**Expected:**
```
✅ Invalid input properly handled
✅ Error recovery validated
   Generated recipe after error: [Recipe Name]
```

---

## Before Running Tests - Checklist

### 1. Verify Model File in Xcode Bundle

**Check in Xcode:**
1. Open `Cooking App.xcworkspace`
2. Find `cooking_assistant.task` in Project Navigator (left sidebar)
3. Select the file and check **File Inspector** (right sidebar)
4. Verify **Target Membership**: "Cooking App" should be ✅ checked

**If not checked:**
- Check the box next to "Cooking App"
- Or drag the file into the project again with "Add to target" selected

### 2. Verify Build Phases

1. Select the project in Project Navigator
2. Select "Cooking App" target
3. Go to **Build Phases** tab
4. Expand **Copy Bundle Resources**
5. Verify `cooking_assistant.task` is listed

**If not listed:**
- Click the "+" button
- Add `cooking_assistant.task`

### 3. Verify MediaPipe Dependencies

**Check Podfile:**
```ruby
pod 'MediaPipeTasksGenAI'
pod 'MediaPipeTasksGenAIC'
```

**Verify installation:**
```bash
cd "/path/to/Cooking App"
pod install
```

---

## Running Individual Test Suites

### Run Only MediaPipe Tests

In Xcode Test Navigator:
1. Press ⌘+6 (Test Navigator)
2. Find "MediaPipe Model Integration Tests"
3. Click the ▶︎ button next to the suite

### Run Specific Test

```bash
# Test model file validation only
xcodebuild test \
  -workspace "Cooking App.xcworkspace" \
  -scheme "Cooking App" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:"Cooking AppTests/MediaPipeIntegrationTests/validateConvertedModelFile()"
```

---

## Troubleshooting

### ❌ Test 10 Fails: "Model file not found"

**Problem:** Model not in bundle.

**Solution:**
```bash
# Check if file exists in app bundle
ls -lh "Cooking App/cooking_assistant.task"

# Size should be ~5 GB
```

If file exists but test fails:
1. Clean build folder: ⌘+Shift+K
2. Rebuild: ⌘+B
3. Run tests again: ⌘+U

### ❌ Test 11 Fails: "MediaPipe dependencies missing"

**Problem:** MediaPipe frameworks not installed.

**Solution:**
```bash
cd "/path/to/Cooking App"
pod install
```

### ❌ Test 12 Fails: Model loading error

**Problem:** Model file corrupted or incompatible.

**Possible causes:**
- Incomplete download
- Wrong file format
- Incompatible MediaPipe version

**Solution:**
```bash
# Check file size
ls -lh "Cooking App/cooking_assistant.task"

# Should be approximately 5 GB (4,900,000,000 - 5,100,000,000 bytes)
```

If size is wrong, reconvert the model following `colab_conversion_prompt.md`.

### ⚠️ Test 13 Slow: Generation takes > 60 seconds

**Problem:** Performance slower than expected.

**Possible causes:**
- First run (model needs to warm up)
- Simulator instead of device
- Insufficient device resources

**Solutions:**
1. **Run on real device** - Much faster than simulator
2. **Wait for second generation** - First is often slower
3. **Check device specs** - iPhone 12 Pro or newer recommended

### ❌ Test 13 Fails: Invalid JSON response

**Problem:** Model generates invalid output.

**Check RecipeParser error:**
```swift
// Look for parsing errors in console
// RecipeParser should show what went wrong
```

**Solutions:**
1. Check prompt format in `RecipeGenerator.buildJSONPrompt()`
2. Verify model was trained with correct format
3. Adjust temperature/topK parameters

---

## Performance Benchmarks

### Expected Performance (Real Device - iPhone 14 Pro or newer)

| Test | Target | Acceptable | Too Slow |
|------|--------|------------|----------|
| Model Loading (Test 12) | < 10s | 10-30s | > 30s |
| First Generation (Test 13) | < 20s | 20-45s | > 60s |
| Subsequent Generations | < 15s | 15-30s | > 45s |
| Average (Test 15) | < 20s | 20-40s | > 60s |

### Expected Performance (Simulator)

**Note:** Simulator is 2-5x slower than real devices.

| Test | Expected |
|------|----------|
| Model Loading | 30-60s |
| Generation | 30-90s |

**Recommendation:** For accurate performance testing, use a real device.

---

## After Tests Pass

### 1. Update README Status

Update `/repo/README.md` with:
```markdown
## App Status: ✅ Fully Functional with Real LLM

The app is now running with the real MediaPipe model:
- Model: cooking_assistant.task (5 GB)
- MediaPipe: v0.10.24
- Tests: All 16 tests passing
```

### 2. Test in App UI

1. Run the app: ⌘+R
2. Tap "Generate Recipe"
3. Wait for generation (should NOT be 2-second simulation)
4. Verify real recipe output

**Look for in console:**
```
MediaPipe model setup complete
```

### 3. Performance Optimization (If Needed)

If generation is too slow, try:

```swift
// In RecipeGenerator.setupModel()
let options = LlmInference.Options(modelPath: modelPath)
options.maxTokens = 256  // Reduce from 512
options.maxTopk = 20     // Reduce from 40
```

### 4. Production Readiness

Before App Store submission:
- [ ] Test on multiple devices (iPhone 12+)
- [ ] Test with low battery mode
- [ ] Test with poor network (model should work offline)
- [ ] Test memory usage under stress
- [ ] Test app cold start with large model
- [ ] Add proper error messages to UI

---

## Quick Command Reference

```bash
# Open workspace
open "Cooking App.xcworkspace"

# Run all tests
xcodebuild test -workspace "Cooking App.xcworkspace" -scheme "Cooking App" -destination "platform=iOS Simulator,name=iPhone 16 Pro"

# Clean build
xcodebuild clean -workspace "Cooking App.xcworkspace" -scheme "Cooking App"

# Install dependencies
pod install

# Check model file
ls -lh "Cooking App/cooking_assistant.task"

# Build only
xcodebuild build -workspace "Cooking App.xcworkspace" -scheme "Cooking App"
```

---

## Success Criteria

### All Tests Pass ✅

You should see:
```
Test Suite 'All tests' passed
     16 tests passed
```

### Console Output Shows:

```
✅ Model file validated: ~5000 MB
✅ MediaPipe framework loaded successfully
✅ MediaPipe model loaded successfully in X.XX seconds
✅ Real recipe generated in X.XX seconds
📜 Title: [Actual Recipe Name]
🥘 Ingredients: [4+]
📋 Instructions: [3+]
📊 MediaPipe Performance: Average X.XX s
✅ Error recovery validated
```

### App Works:

1. No more 2-second simulation
2. Real recipes generated
3. Proper JSON structure
4. Quality recipe content

---

## Next Steps After Tests Pass

1. **Optimize Performance** (if needed)
   - Adjust parameters
   - Test on various devices
   - Implement caching strategies

2. **Enhance UI**
   - Add progress indicators
   - Show generation status
   - Display better loading states

3. **Add Features**
   - Recipe history persistence
   - Favorite recipes
   - Export/share functionality
   - Custom ingredient input

4. **Prepare for Release**
   - Beta testing
   - Performance profiling
   - Memory optimization
   - App Store assets

---

## Support

If tests fail unexpectedly:
1. Check the console output for specific error messages
2. Review the troubleshooting section above
3. Verify all prerequisites are met
4. Try running tests individually to isolate issues

Good luck! 🧑‍🍳📱
