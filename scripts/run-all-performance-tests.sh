#!/bin/bash

# Get script location and change to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."  # Go to server/ directory

echo "🚀 Running all K6 performance tests from $(pwd)"
echo ""

# Find all .js files in performance-tests directory
TEST_FILES=(performance-tests/*.js)

# Check if any test files were found
if [ ! -e "${TEST_FILES[0]}" ]; then
  echo "❌ No test files found in performance-tests/"
  exit 1
fi

echo "Found ${#TEST_FILES[@]} test file(s)"
echo ""

# Run each test
for test_path in "${TEST_FILES[@]}"; do
  test_name=$(basename "$test_path")
  echo "📊 Running: $test_name"
  k6 run "$test_path"
  echo "✅ Completed: $test_name"
  echo ""
done

echo ""
echo "🎉 All tests completed!"