#!/bin/bash

# Check if models.ini exists in parent directory
MODELS_INI="../../spout/config/models.ini"
if [ ! -f "$MODELS_INI" ]; then
    echo "Error: Cannot find models.ini at $MODELS_INI"
    echo "Please ensure you're running this script from the testing directory"
    exit 1
fi

# Directory paths
PROMPTS_DIR="../prompts"
TESTS_DIR="../tests"

# Create tests directory if it doesn't exist
mkdir -p "$TESTS_DIR"

# Function to extract active models from models.ini
get_active_models() {
    while IFS='=' read -r line || [ -n "$line" ]; do
        [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^\[.*\]$ ]] && continue
        model=$(echo "$line" | cut -d'=' -f1)
        status=$(echo "$line" | cut -d'=' -f2)
        if [ "$status" = "1" ]; then
            echo "$model" | tr -d ' '
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

# Get list of non-empty text files and directories (only direct children of PROMPTS_DIR)
files=($(find "$PROMPTS_DIR" -maxdepth 1 -type f -name "*.txt" -not -empty -o -type d ! -path "$PROMPTS_DIR"))

if [ ${#files[@]} -eq 0 ]; then
    echo "No text files found in prompts directory."
    exit 1
fi

# Display available files
echo -e "\nAvailable prompt files:"
for i in "${!files[@]}"; do
    echo "$((i+1)). $(basename "${files[$i]}")"
done

# Get user selection
while true; do
    echo -e "\nSelect a file number: "
    read selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#files[@]}" ]; then
        selected_path="${files[$((selection-1))]}"
        
        # Check if selection is a directory
        if [ -d "$selected_path" ]; then
            # Get txt files in the selected directory
            dir_files=($(find "$selected_path" -type f -name "*.txt" -not -empty))
            
            if [ ${#dir_files[@]} -eq 0 ]; then
                echo "No text files found in selected directory."
                continue
            elif [ ${#dir_files[@]} -eq 1 ]; then
                selected_file="${dir_files[0]}"
                break
            else
                # Show files in directory
                echo -e "\nFiles in selected directory:"
                echo "0. All files"
                for i in "${!dir_files[@]}"; do
                    echo "$((i+1)). $(basename "${dir_files[$i]}")"
                done
                
                # Get sub-selection
                while true; do
                    echo -e "\nSelect a file number (0 for all): "
                    read sub_selection
                    if [ "$sub_selection" -eq 0 ]; then
                        selected_file="ALL"
                        selected_files=("${dir_files[@]}")
                        break
                    elif [[ "$sub_selection" =~ ^[0-9]+$ ]] && [ "$sub_selection" -ge 1 ] && [ "$sub_selection" -le "${#dir_files[@]}" ]; then
                        selected_file="${dir_files[$((sub_selection-1))]}"
                        break
                    else
                        echo "Invalid selection. Please try again."
                    fi
                done
                break
            fi
        else
            selected_file="$selected_path"
            break
        fi
    else
        echo "Invalid selection. Please try again."
    fi
done

# Create results file with timestamp
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
results_file="$TESTS_DIR/prompt_gamut-$timestamp.txt"

# Initialize results file
{
    if [ "$selected_file" = "ALL" ]; then
        echo "Prompt Gamut Results for multiple files from $(basename "$(dirname "${selected_files[0]}")") - $timestamp"
    else
        echo "Prompt Gamut Results for $(basename "$selected_file") - $timestamp"
    fi
    echo "==================="
    echo "Testing across ${#active_models[@]} models"
    echo ""
} > "$results_file"

# Initialize total duration
total_duration=0

# Test each model
for model in "${active_models[@]}"; do
    echo -e "\nTesting model: $model"
    echo "----------------------------------------"
    
    # Record start time
    start_time=$(date +%s)
    
    # Switch to the model
    spout -p "$model"
    
    # Add model header to results
    {
        echo "Model: $model"
        echo "----------------------------------------"
        echo ""
    } >> "$results_file"
    
    if [ "$selected_file" = "ALL" ]; then
        for file in "${selected_files[@]}"; do
            echo -e "\nProcessing file: $(basename "$file")"
            echo -e "\nFile: $(basename "$file")" >> "$results_file"
            echo "===================" >> "$results_file"
            
            while IFS= read -r prompt; do
                # Skip if prompt is empty or only whitespace
                if [ -z "${prompt// }" ]; then
                    continue
                fi
                
                echo -e "\nProcessing prompt: $prompt"
                echo -e "\nPrompt:" >> "$results_file"
                echo "$prompt" >> "$results_file"
                
                output=$(spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "$prompt" 2>&1)
                execution_time=$(echo "$output" | grep -o "Execution time: [0-9.]*ms" | sed 's/Execution time: //')
                response=$(echo "$output" | grep -v "Execution time:")
                
                echo -e "\nResponse (${execution_time}):" >> "$results_file"
                echo "$response" >> "$results_file"
                echo -e "\n-------------------\n" >> "$results_file"
                
            done < <(grep -v '^[[:space:]]*$' "$file")
            
            echo "===================" >> "$results_file"
        done
    else
        while IFS= read -r prompt; do
            # Skip if prompt is empty or only whitespace
            if [ -z "${prompt// }" ]; then
                continue
            fi
            
            echo -e "\nProcessing prompt: $prompt"
            echo -e "\nPrompt:" >> "$results_file"
            echo "$prompt" >> "$results_file"
            
            output=$(spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "$prompt" 2>&1)
            execution_time=$(echo "$output" | grep -o "Execution time: [0-9.]*ms" | sed 's/Execution time: //')
            response=$(echo "$output" | grep -v "Execution time:")
            
            echo -e "\nResponse (${execution_time}):" >> "$results_file"
            echo "$response" >> "$results_file"
            echo -e "\n-------------------\n" >> "$results_file"
            
        done < <(grep -v '^[[:space:]]*$' "$selected_file")
    fi
    
    # Record end time and calculate duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    total_duration=$((total_duration + duration))
    
    # Format duration as minutes and seconds
    minutes=$((duration / 60))
    seconds=$((duration % 60))
    duration_formatted="${minutes}m ${seconds}s"
    
    # Add duration to results
    {
        echo "Duration: $duration_formatted"
        echo "========================================="
        echo ""
    } >> "$results_file"
    
    echo "Completed in: $duration_formatted"
    echo "----------------------------------------"
done

# Format total time
total_hours=$((total_duration / 3600))
total_minutes=$(((total_duration % 3600) / 60))
total_seconds=$((total_duration % 60))

# Add summary to results file
{
    echo "Summary"
    echo "======="
    echo "Total Models Tested: ${#active_models[@]}"
    echo "Total Duration: ${total_hours}h ${total_minutes}m ${total_seconds}s"
    echo "Average Duration: $((total_duration / ${#active_models[@]} / 60))m $((total_duration / ${#active_models[@]} % 60))s"
} >> "$results_file"

echo -e "\nTesting completed!"
echo "Total Duration: ${total_hours}h ${total_minutes}m ${total_seconds}s"
echo "Results saved to: $results_file"
