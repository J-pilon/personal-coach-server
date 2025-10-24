#!/bin/bash

# Get script location and change to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."  # Go to server/ directory

echo "🚀 Running all K6 performance tests from $(pwd)"
echo ""

# Output directory for JSON results
RESULTS_DIR="performance-tests/results"
mkdir -p "$RESULTS_DIR"

# Clean previous results
rm -f "$RESULTS_DIR"/*.json

# Find all .js files in performance-tests directory
TEST_FILES=(performance-tests/*.js)

# Check if any test files were found
if [ ! -e "${TEST_FILES[0]}" ]; then
  echo "❌ No test files found in performance-tests/"
  exit 1
fi

echo "Found ${#TEST_FILES[@]} test file(s)"
echo ""

# Run each test and export JSON summary
for test_path in "${TEST_FILES[@]}"; do
  test_name=$(basename "$test_path" .js)
  
  echo "📊 Running: ${test_name}.js"
  
  # Use K6's --summary-export flag to output JSON results
  k6 run "$test_path" --summary-export="${RESULTS_DIR}/${test_name}.json"
  # k6 run --out json="${RESULTS_DIR}/${test_name}.json" "$test_path"
  
  echo "✅ Completed: ${test_name}.js"
  echo ""
done

# Aggregate all JSON files into one
echo "📊 Aggregating results..."

# Build aggregated JSON manually
echo "{" > "$RESULTS_DIR/aggregated.json"
first=true

for json_file in "$RESULTS_DIR"/*.json; do
  # Skip the aggregated file itself
  [[ "$(basename "$json_file")" == "aggregated.json" ]] && continue
  
  test_name=$(basename "$json_file" .json)
  
  # Add comma between entries (not for first item)
  if [ "$first" = false ]; then
    echo "," >> "$RESULTS_DIR/aggregated.json"
  fi
  first=false
  
  # Add test name as key and its JSON content
  echo "  \"${test_name}\": " >> "$RESULTS_DIR/aggregated.json"
  cat "$json_file" | sed 's/^/  /' >> "$RESULTS_DIR/aggregated.json"
done

echo "" >> "$RESULTS_DIR/aggregated.json"
echo "}" >> "$RESULTS_DIR/aggregated.json"

# Pretty-print with jq if available
if command -v jq &> /dev/null; then
  jq '.' "$RESULTS_DIR/aggregated.json" > "$RESULTS_DIR/aggregated-pretty.json"
  mv "$RESULTS_DIR/aggregated-pretty.json" "$RESULTS_DIR/aggregated.json"
  echo "✅ Results aggregated and formatted: $RESULTS_DIR/aggregated.json"
else
  echo "✅ Results aggregated: $RESULTS_DIR/aggregated.json"
  echo "💡 Tip: Install 'jq' for pretty-printed JSON"
fi

echo ""
echo "🎉 All tests completed!"
echo ""
echo "📄 Individual results: $RESULTS_DIR/<test_name>.json"
echo "📄 Aggregated results: $RESULTS_DIR/aggregated.json"