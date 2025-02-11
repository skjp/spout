#!/bin/bash

# Check if models.ini exists in parent directory
MODELS_INI="../../spout/config/models.ini"
if [ ! -f "$MODELS_INI" ]; then
    echo "Error: Cannot find models.ini at $MODELS_INI"
    echo "Please ensure you're running this script from the testing directory"
    exit 1
fi

# Create tests directory if it doesn't exist
mkdir -p ../tests

# Generate timestamp for test files
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SUMMARY_FILE="../tests/gamut_summary-${TIMESTAMP}.txt"

# Initialize summary file with list of models to be tested
{
    echo "Model Performance Summary - ${TIMESTAMP}"
    echo "================================="
    echo ""
    echo "Models to be tested:"
    echo "-----------------"
    for model in "${active_models[@]}"; do
        echo "- $model"
    done
    echo ""
    echo "Test Results:"
    echo "============"
    echo ""
} > "${SUMMARY_FILE}"

# Function to extract active models from models.ini
get_active_models() {
    while IFS='=' read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Skip section headers
        [[ "$line" =~ ^\[.*\]$ ]] && continue
        
        # Split line into model and status
        model=$(echo "$line" | cut -d'=' -f1)
        status=$(echo "$line" | cut -d'=' -f2)
        
        # Only process lines with =1
        if [ "$status" = "1" ]; then
            # Remove any whitespace
            model=$(echo "$model" | tr -d ' ')
            echo "$model"
        fi
    done < "$MODELS_INI"
}

# Get list of active models
active_models=($(get_active_models))

# Check if we found any active models
if [ ${#active_models[@]} -eq 0 ]; then
    echo "Error: No active models found in $MODELS_INI"
    exit 1
fi

echo "Starting comprehensive model testing across ${#active_models[@]} models..."
echo "Results will be saved to: ${SUMMARY_FILE}"
echo ""

# Initialize total duration
total_duration=0

# Test each model
for model in "${active_models[@]}"; do
    echo "Testing model: $model"
    echo "----------------------------------------"
    
    # Record start time
    start_time=$(date +%s)
    
    # Switch to the model and run core tests
    spout -p "$model"
    
    # Run core tests and capture the output
    core_test_output=$(./test_core.sh)
    
    # Extract test file path and pass rate
    test_file=""
    pass_rate="0.0%"
    
    # Look for the results file path in the output
    if [[ "$core_test_output" =~ "Results saved to" ]]; then
        test_file=$(echo "$core_test_output" | grep "Results saved to" | cut -d' ' -f5)
        
        # If we found a test file, extract the pass rate directly from the output
        if [[ "$core_test_output" =~ "Overall Pass Rate: "([0-9]+\.?[0-9]*)"%" ]]; then
            pass_rate="${BASH_REMATCH[1]}%"
        fi
    fi
    
    # Record end time and calculate duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    total_duration=$((total_duration + duration))
    
    # Format duration as minutes and seconds
    minutes=$((duration / 60))
    seconds=$((duration % 60))
    duration_formatted="${minutes}m ${seconds}s"
    
    # Add to summary file (without detailed test output)
    {
        echo "Model: $model"
        echo "Pass Rate: $pass_rate"
        echo "Duration: $duration_formatted"
        echo "Core Test Results: $(echo "$core_test_output" | grep -v "Testing")"
        echo "----------------------------------------"
        echo ""
    } >> "${SUMMARY_FILE}"
    
    # Print progress to terminal (including detailed output)
    echo "$core_test_output"
    echo "Pass Rate: $pass_rate"
    echo "Duration: $duration_formatted"
    echo "----------------------------------------"
    echo ""
done

# Calculate average statistics
total_pass_rate=0
model_count=${#active_models[@]}

for model in "${active_models[@]}"; do
    pass_rate=$(grep "Model: $model" -A 1 "${SUMMARY_FILE}" | grep "Pass Rate:" | cut -d' ' -f3 | tr -d '%')
    if [[ "$pass_rate" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        total_pass_rate=$(awk "BEGIN {print $total_pass_rate + $pass_rate}")
    fi
done

# Calculate averages and format total time
avg_pass_rate=$(awk "BEGIN {printf \"%.1f\", $total_pass_rate / $model_count}")
total_hours=$((total_duration / 3600))
total_minutes=$(((total_duration % 3600) / 60))
total_seconds=$((total_duration % 60))
avg_duration=$((total_duration / model_count))
avg_minutes=$((avg_duration / 60))
avg_seconds=$((avg_duration % 60))

# Add summary statistics to file
{
    echo "Summary Statistics"
    echo "=================="
    echo "Total Models Tested: $model_count"
    echo "Total Duration: ${total_hours}h ${total_minutes}m ${total_seconds}s"
    echo "Average Duration: ${avg_minutes}m ${avg_seconds}s"
    echo "Average Pass Rate: ${avg_pass_rate}%"
    echo ""
    echo "Models Tested Successfully:"
    echo "-------------------------"
    for model in "${active_models[@]}"; do
        pass_rate=$(grep "Model: $model" -A 1 "${SUMMARY_FILE}" | grep "Pass Rate:" | cut -d' ' -f3)
        echo "- $model ($pass_rate)"
    done
    echo ""
} >> "${SUMMARY_FILE}"

# Print final summary to terminal
echo "Testing completed!"
echo "Total Models Tested: $model_count"
echo "Total Duration: ${total_hours}h ${total_minutes}m ${total_seconds}s"
echo "Average Duration: ${avg_minutes}m ${avg_seconds}s"
echo "Average Pass Rate: ${avg_pass_rate}%"
echo "Full results saved to: ${SUMMARY_FILE}"
