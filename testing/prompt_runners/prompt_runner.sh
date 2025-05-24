#!/bin/bash

# Directory paths
PROMPTS_DIR="../prompts"
TESTS_DIR="../tests"

# Create tests directory if it doesn't exist
mkdir -p "$TESTS_DIR"

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
results_file="$TESTS_DIR/conversation_test-$timestamp.txt"

# Get model information from settings.ini for the title
SETTINGS_FILE="../../spout/config/settings.ini"
model_name_for_title_segment=""
if [ -f "$SETTINGS_FILE" ]; then
    # Grep for the line containing PreferredModel.
    # sed: 1. Remove everything up to and including the first '='.
    #      2. Trim leading spaces from the value.
    #      3. Trim trailing spaces from the value.
    model_name_value=$(grep "PreferredModel" "$SETTINGS_FILE" | sed 's/[^=]*=//;s/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$model_name_value" ]; then # Check if model_name_value is not empty
        model_name_for_title_segment=" using $model_name_value"
    fi
fi

# Construct the title line for the results file.
# This uses > to overwrite/create the file.
# If selected_file is "ALL", basename will correctly output "ALL".
echo "Prompting Results for $(basename "$selected_file")$model_name_for_title_segment - $timestamp" > "$results_file"
echo "===================" >> "$results_file"
echo >> "$results_file"

# Modify the processing section to handle multiple files
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
            
            # Run spout converse command with timing measurement and empty history
            output=$(spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "$prompt" 2>&1)
            execution_time=$(echo "$output" | grep -o "Execution time: [0-9.]*ms" | sed 's/Execution time: //')
            # Extract response, excluding "Execution time:" line
            raw_response_content=$(echo "$output" | grep -v "Execution time:")
            # Filter out "Binary file (standard input) matches"
            filtered_response_content=$(echo "$raw_response_content" | grep -v "Binary file (standard input) matches")
            
            # Print to terminal
            echo -e "\nResponse (${execution_time}):"
            echo "$filtered_response_content"
            echo -e "\n-------------------"
            
            # Save to results file
            echo -e "\nResponse (${execution_time}):" >> "$results_file"
            echo "$filtered_response_content" >> "$results_file"
            echo -e "\n-------------------\n" >> "$results_file"
            
        done < <(grep -v '^[[:space:]]*$' "$file")
        
        echo "===================" >> "$results_file"
    done
else
    # Read and process prompts
    while IFS= read -r prompt; do
        # Skip if prompt is empty or only whitespace
        if [ -z "${prompt// }" ]; then
            continue
        fi
        
        echo -e "\nProcessing prompt: $prompt"
        echo -e "\nPrompt:" >> "$results_file"
        echo "$prompt" >> "$results_file"
        
        # Run spout converse command with timing measurement and empty history
        output=$(spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "$prompt" 2>&1)
        execution_time=$(echo "$output" | grep -o "Execution time: [0-9.]*ms" | sed 's/Execution time: //')
        # Extract response, excluding "Execution time:" line
        raw_response_content=$(echo "$output" | grep -v "Execution time:")
        # Filter out "Binary file (standard input) matches"
        filtered_response_content=$(echo "$raw_response_content" | grep -v "Binary file (standard input) matches")
        
        # Print to terminal
        echo -e "\nResponse (${execution_time}):"
        echo "$filtered_response_content"
        echo -e "\n-------------------"
        
        # Save to results file
        echo -e "\nResponse (${execution_time}):" >> "$results_file"
        echo "$filtered_response_content" >> "$results_file"
        echo -e "\n-------------------\n" >> "$results_file"
        
    done < <(grep -v '^[[:space:]]*$' "$selected_file")
fi

echo -e "\nResults saved to: $results_file"
