#!/bin/bash

# Run Model Tests Script
# Tests the cooking_assistant_v3.task model with MediaPipe integration

set -e

echo "🧪 Cooking Assistant Model Test Runner"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE="Cooking App.xcworkspace"
SCHEME="Cooking App"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"
MODEL_FILE="Cooking App/cooking_assistant_v3.task"

# Step 1: Check prerequisites
echo -e "${BLUE}Step 1: Checking prerequisites...${NC}"
echo ""

# Check if workspace exists
if [ ! -d "$WORKSPACE" ]; then
    echo -e "${RED}❌ Error: Workspace not found at '$WORKSPACE'${NC}"
    echo "   Make sure you're in the project root directory."
    exit 1
fi
echo -e "${GREEN}✅ Workspace found${NC}"

# Check if model file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo -e "${RED}❌ Error: Model file not found at '$MODEL_FILE'${NC}"
    echo "   Please add cooking_assistant_v3.task to the project."
    exit 1
fi

# Check model file size
MODEL_SIZE=$(stat -f%z "$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_FILE" 2>/dev/null)
MODEL_SIZE_MB=$((MODEL_SIZE / 1024 / 1024))

if [ $MODEL_SIZE_MB -lt 100 ]; then
    echo -e "${RED}❌ Error: Model file is too small (${MODEL_SIZE_MB} MB)${NC}"
    echo "   Expected: ~5000 MB"
    echo "   The file may be corrupt or incomplete."
    exit 1
fi
echo -e "${GREEN}✅ Model file found (${MODEL_SIZE_MB} MB)${NC}"

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: xcodebuild not found${NC}"
    echo "   Make sure Xcode Command Line Tools are installed."
    exit 1
fi
echo -e "${GREEN}✅ xcodebuild available${NC}"

echo ""

# Step 2: Run tests
echo -e "${BLUE}Step 2: Running tests...${NC}"
echo ""
echo "This will test:"
echo "  • Phase 1: Architecture validation (9 tests)"
echo "  • Phase 2-3: MediaPipe integration (7 tests)"
echo ""
echo -e "${YELLOW}⏳ Starting test run (this may take several minutes)...${NC}"
echo ""

# Run tests with output
xcodebuild test \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    | tee test_output.log

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run the app to test UI (⌘+R in Xcode)"
    echo "  2. Tap 'Generate Recipe' to test real model"
    echo "  3. Check console for 'MediaPipe model setup complete'"
    echo ""
    echo "Full test output saved to: test_output.log"
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}❌ Some tests failed${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check test_output.log for details"
    echo "  2. See TEST_COOKING_ASSISTANT_MODEL.md for help"
    echo "  3. Verify model file is in Xcode target"
    echo ""
    exit 1
fi
