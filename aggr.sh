#!/bin/bash

# Load .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

# Configuration directory
config_dir="./configs"

# Default configuration file name
default_config="default"

# Use the first script argument as the config file name, or default if none is provided
config_file="${1:-$default_config}.sh"

# Check if the configuration file exists, otherwise exit with error
if [ ! -f "$config_dir/$config_file" ]; then
    echo "Configuration file not found: $config_dir/$config_file"
    exit 1
fi

# Load the configuration
source "$config_dir/$config_file"

# Saves directory and custom subfolder path
saves_dir="./saves"
custom_dir="${saves_dir}/${custom_subfolder}"

# Current timestamp for the saved file name
timestamp=$(date +"%Y%m%d%H%M%S")

# Decide whether to add timestamp based on the configuration
if [ "$include_timestamp" = true ]; then
    aggregate="${custom_dir}/${aggr_file_name}_${timestamp}.txt"
else
    aggregate="${custom_dir}/${aggr_file_name}.txt"
fi

# Check and create custom subdirectory within saves if not exists
mkdir -p "$custom_dir"

# Empty the aggregate file if it exists or create a new one
> "$aggregate"

# function to document / summarize the aggregated file
summarize_with_openai() {
    local file_content=$1
    local prompt_text="You are a helpful assistant. Summarize the following shell scripts and describe the purpose and function of files, functions, and variables:"

    # Your OpenAI API key should be read from an environment variable
    local openai_api_key=$OPENAI_API_KEY

    # API endpoint for OpenAI Chat
    local openai_endpoint="https://api.openai.com/v1/chat/completions"

    # Prepare the data for the API call
    local data=$(jq -n \
        --arg prompt "$prompt_text" \
        --arg content "$file_content" \
        '{model: "gpt-4-1106-preview", messages: [{"role": "system", "content": $prompt}, {"role": "user", "content": $content}]}')

    # Make the API call and store the response
    local summary_response=$(curl -s -X POST $openai_endpoint \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $openai_api_key" \
        -d "$data")

    # Extract the text from the response
    local summary=$(echo "$summary_response" | jq -r '.choices[0].message.content')

    # Check for errors in the response
    if [[ "$summary" == "" || "$summary" == "null" ]]; then
        local error_message=$(echo "$summary_response" | jq -r '.error.message')
        if [[ "$error_message" != "null" ]]; then
            echo "Error from OpenAI: $error_message"
            return 1
        else
            echo "No summary was provided or an unknown error occurred."
            return 1
        fi
    fi

    echo "$summary"
}

# Construct the find command
find_command="find \"$root_dir\" -type f"

# Add inclusion patterns for file extensions
for ext in "${extensions[@]}"; do
    find_command+=" -iname \"*.$ext\""
done

# Add exclusion patterns for directories and files
exclusion_conditions=()
for exclusion in "${exclusions[@]}"; do
    # Check if exclusion is a directory or a file
    if [[ -d "$root_dir/$exclusion" ]]; then
        # It's a directory, exclude directory matches
        exclusion_conditions+=("-path \"$root_dir/$exclusion/*\"")
    elif [[ -f "$root_dir/$exclusion" ]]; then
        # It's a file, exclude file matches
        exclusion_conditions+=("-name \"$exclusion\"")
    else
        # Assume any other pattern is a glob and handle it accordingly
        exclusion_conditions+=("-name \"$exclusion\"")
    fi
done

# Join all exclusion conditions
if [ ${#exclusion_conditions[@]} -ne 0 ]; then
    for condition in "${exclusion_conditions[@]}"; do
        find_command+=" ! \( $condition \)"
    done
fi

# Execute the find command and process files
eval $find_command | while IFS= read -r file; do
    # Check if the file exists
    if [ -f "$file" ]; then
        # Convert POSIX path back to Windows path for output
        win_path=$(echo $file | sed 's/\//\\/g' | sed 's/^./\0:/')
        # Write the file path/name to the aggregate file
        echo "//$win_path" >> "$aggregate"
        # Append the file contents to the aggregate file
        cat "$file" >> "$aggregate"
        # Add separator lines between each file's content
        echo -e "\n\n\n" >> "$aggregate"
    else
        echo "Error: $file not found."
    fi
done

# Call the summarize function with its contents
if [ -s "$aggregate" ]; then
    aggregate_content=$(<"$aggregate")
    summary=$(summarize_with_openai "$aggregate_content")
    echo "Summary:"
    echo "$summary"
else
    echo "Aggregate file is empty or does not exist."
fi

echo "Aggregation complete. Check $aggregate for the combined contents."