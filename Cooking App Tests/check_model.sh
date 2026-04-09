#!/bin/bash

# Quick Model Validation Script
# Checks if cooking_assistant.task is ready for testing

echo "🔍 Quick Model Validation"
echo "========================"
echo ""

MODEL_FILE="Cooking App/cooking_assistant_v3.task"

# Check if file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ Model file not found at '$MODEL_FILE'"
    exit 1
fi

# Get file size
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    MODEL_SIZE=$(stat -f%z "$MODEL_FILE")
else
    # Linux
    MODEL_SIZE=$(stat -c%s "$MODEL_FILE")
fi

MODEL_SIZE_MB=$((MODEL_SIZE / 1024 / 1024))
MODEL_SIZE_GB=$(echo "scale=2; $MODEL_SIZE_MB / 1024" | bc)

echo "📁 File: $MODEL_FILE"
echo "📊 Size: ${MODEL_SIZE_MB} MB (~${MODEL_SIZE_GB} GB)"
echo ""

# Validate size
if [ $MODEL_SIZE_MB -lt 100 ]; then
    echo "❌ FAIL: File is too small (< 100 MB)"
    echo "   Expected: ~5000 MB (5 GB)"
    echo "   This is likely a sparse or corrupt file."
    exit 1
elif [ $MODEL_SIZE_MB -lt 4500 ]; then
    echo "⚠️  WARNING: File smaller than expected"
    echo "   Expected: ~5000 MB"
    echo "   Found: ${MODEL_SIZE_MB} MB"
    echo "   The file may work but could be incomplete."
elif [ $MODEL_SIZE_MB -gt 5500 ]; then
    echo "⚠️  WARNING: File larger than expected"
    echo "   Expected: ~5000 MB"
    echo "   Found: ${MODEL_SIZE_MB} MB"
    echo "   This is unusual but may still work."
else
    echo "✅ PASS: File size is correct (~5 GB)"
fi

# Check if file is readable
if [ -r "$MODEL_FILE" ]; then
    echo "✅ PASS: File is readable"
else
    echo "❌ FAIL: File is not readable"
    exit 1
fi

# Check if file appears to be binary
if file "$MODEL_FILE" | grep -q "data"; then
    echo "✅ PASS: File appears to be binary data"
else
    echo "⚠️  WARNING: File may not be binary"
    file "$MODEL_FILE"
fi

echo ""
echo "Summary:"
echo "--------"

if [ $MODEL_SIZE_MB -ge 4500 ] && [ $MODEL_SIZE_MB -le 5500 ]; then
    echo "✅ Model file looks good!"
    echo ""
    echo "Next steps:"
    echo "  1. Make sure file is added to Xcode target"
    echo "  2. Run: ./run_model_tests.sh"
    echo "  3. Or in Xcode: ⌘+U to run tests"
    exit 0
else
    echo "⚠️  Model file size is unusual"
    echo ""
    echo "You may want to:"
    echo "  1. Verify the download completed successfully"
    echo "  2. Re-convert the model if needed"
    echo "  3. Check colab_conversion_prompt.md for guidance"
    exit 1
fi
