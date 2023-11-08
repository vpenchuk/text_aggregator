#!/bin/bash

# Load .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

# New configuration directories under the 'configs' directory
profile_config_dir="./configs/profiles"
prompt_config_dir="./configs/prompts"

# Default configuration file names
default_profile_config="default-profile"
default_prompt_config="default-prompt"

# Use the first script argument as the profile config file name, or default if none is provided
profile_config_file="${1:-$default_profile_config}.sh"

# Use the second script argument as the prompt config file name, or default if none is provided
prompt_config_file="${2:-$default_prompt_config}.txt"

# Check if the profile configuration file exists, otherwise exit with error
if [ ! -f "$profile_config_dir/$profile_config_file" ]; then
    echo "Profile configuration file not found: $profile_config_dir/$profile_config_file"
    exit 1
fi

# Check if the prompt configuration file exists, otherwise exit with error
if [ ! -f "$prompt_config_dir/$prompt_config_file" ]; then
    echo "Prompt configuration file not found: $prompt_config_dir/$prompt_config_file"
    exit 1
fi

# Load the profile configuration
source "$profile_config_dir/$profile_config_file"

# Load the OpenAI script
source "$(dirname "$0")/openai.sh"

# Load the prompt configuration
prompt_text=$(cat "$prompt_config_dir/$prompt_config_file")

# Saves directory and custom subfolder path
saves_dir="./saves"
custom_dir="${saves_dir}/${custom_subfolder}"

# File to store the list of found files


# Empty the found files list file if it exists or create a new one
> "$found_files_list"

# Current timestamp for the saved file name
timestamp=$(date +"%Y%m%d%H%M%S")

# Decide whether to add timestamp based on the configuration
if [ "$include_timestamp" = true ]; then
    aggregate="${custom_dir}/${aggr_file_name}_${timestamp}.txt"
    found_files_list="${custom_dir}/files_list_${timestamp}.txt"
else
    aggregate="${custom_dir}/${aggr_file_name}.txt"
    found_files_list="${custom_dir}/files_list.txt"
fi

# Check and create custom subdirectory within saves if not exists
mkdir -p "$custom_dir"

# Empty the aggregate file if it exists or create a new one
> "$aggregate"

# Construct the find command as an array
find_command=( find "$root_dir" -type f )

# Add inclusion patterns for file extensions
for ext in "${extensions[@]}"; do
    find_command+=( -iname "*.$ext" )
done

# Add exclusion patterns for directories and files
for exclusion in "${exclusions[@]}"; do
    find_command+=( ! -path "$exclusion" -prune )
done

# Execute the find command using array expansion to preserve arguments
while IFS= read -r file; do
    # Check if the file exists
    if [ -f "$file" ]; then
        # Convert POSIX path back to Windows path for output
        win_path=$(echo $file | sed 's/\//\\/g' | sed 's/^./\0:/')
        # Write the file path/name to the aggregate file
        echo "//$win_path" >> "$aggregate"
        echo "$win_path" >> "$found_files_list"
        # Append the file contents to the aggregate file
        cat "$file" >> "$aggregate"
        # Add separator lines between each file's content
        echo -e "\n\n\n" >> "$aggregate"
    else
        echo "Error: $file not found."
    fi
done < <( "${find_command[@]}" )

echo "Aggregation complete. Check $aggregate for the combined contents."

# Call the summarize function with its contents
if [ "$summarization" = true ]; then
    if [ -s "$aggregate" ]; then
        aggregate_content=$(<"$aggregate")
        echo "Calling OpenAI API for Summarization...Please wait..."
        summary=$(summarize_with_prompt "$aggregate_content" "$prompt_text")  # Pass the prompt text to the function
        echo "Summary:"
        echo "$summary"
    else
        echo "Aggregate file is empty or does not exist."
    fi
else
    echo "Summarization OFF"
fi