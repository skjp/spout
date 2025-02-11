#!/bin/bash

# Create tests directory if it doesn't exist
mkdir -p tests

# Generate timestamp for the test file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TEST_OUTPUT_FILE="../tests/core_test-${TIMESTAMP}.txt"

# Array of core modules to test
modules=(
    "reduce"
    "expand" 
    "enhance"
    "search"
    "mutate"
    "generate"
    "iterate"
    "translate"
    "converse"
    "parse"
    "evaluate"
    "imagine"
)

# Create initial output file
echo "Test Results - ${TIMESTAMP}" > "${TEST_OUTPUT_FILE}"
echo "===================" >> "${TEST_OUTPUT_FILE}"
echo "" >> "${TEST_OUTPUT_FILE}"

# Initialize counters
declare -A module_passes
declare -A module_fails

# Function to safely count occurrences in file
count_occurrences() {
    local pattern="$1"
    local file="$2"
    grep -c "$pattern" "$file" 2>/dev/null || echo "0"
}

# Run tests for each module
for module in "${modules[@]}"; do
    echo "Testing ${module}..."
    echo "## ${module} ##" >> "${TEST_OUTPUT_FILE}"
    echo "" >> "${TEST_OUTPUT_FILE}"
    
    # Initialize counters for this module
    initial_passes=$(count_occurrences "\[PASS\]" "${TEST_OUTPUT_FILE}")
    initial_fails=$(count_occurrences "\[FAIL\]" "${TEST_OUTPUT_FILE}")
    let initial_passes=${initial_passes:-0}
    let initial_fails=${initial_fails:-0}
    
    # Run tests and capture output
    spout "$module" -t >> "${TEST_OUTPUT_FILE}"
    
    # Get current counts
    current_passes=$(count_occurrences "\[PASS\]" "${TEST_OUTPUT_FILE}")
    current_fails=$(count_occurrences "\[FAIL\]" "${TEST_OUTPUT_FILE}")
    
    # Initialize values to 0 if empty
    let current_passes=${current_passes:-0}
    let current_fails=${current_fails:-0}
    
    # Calculate module passes and fails
    let module_pass=current_passes-initial_passes
    let module_fail=current_fails-initial_fails
    
    # Store results
    module_passes[$module]=$module_pass
    module_fails[$module]=$module_fail
    
    echo "" >> "${TEST_OUTPUT_FILE}"
    echo "-------------------" >> "${TEST_OUTPUT_FILE}"
    echo "" >> "${TEST_OUTPUT_FILE}"
done

# Calculate final statistics
let total_passes=0
let total_tests=0
summary=""

for module in "${modules[@]}"; do
    # Get stored values with default 0
    let passes=${module_passes[$module]:-0}
    let fails=${module_fails[$module]:-0}
    let total=passes+fails
    
    # Update totals
    let total_passes+=passes
    let total_tests+=total
    
    # Calculate percentage safely
    if [ $total -eq 0 ]; then
        percent="0.0"
    else
        percent=$(awk "BEGIN {printf \"%.1f\", ($passes/$total)*100}")
    fi
    
    summary="${summary}${module}: ${percent}% ($passes/$total)\n"
done

# Calculate overall percentage safely
if [ $total_tests -eq 0 ]; then
    overall_percent="0.0"
else
    overall_percent=$(awk "BEGIN {printf \"%.1f\", ($total_passes/$total_tests)*100}")
fi

# Create final summary at the beginning of the file
temp_file=$(mktemp)
cat "${TEST_OUTPUT_FILE}" > "$temp_file"
{
    echo "Test Results - ${TIMESTAMP}"
    echo "==================="
    echo ""
    echo "Overall Pass Rate: ${overall_percent}% (${total_passes}/${total_tests})"
    echo ""
    echo "Module Results:"
    echo -e "$summary"
    echo ""
    echo "==================="
    echo ""
    cat "$temp_file"
} > "${TEST_OUTPUT_FILE}"
rm "$temp_file"

echo "Tests completed. Results saved to ${TEST_OUTPUT_FILE}"
echo "Overall Pass Rate: ${overall_percent}% (${total_passes}/${total_tests} tests passed)"
