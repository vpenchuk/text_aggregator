#!/bin/bash
# This bash script is designed to aggregate text from files based on configured profiles and prompts,
# and then optionally pass the aggregated content to an OpenAI summarization tool.

# Display a line break for cleaner output
echo >&2

# Import the OpenAI script functions
source "$(dirname "$0")/openai.sh"

# Import the config.sh script
source "$(dirname "$0")/configs/app_config.sh" "$@"

# Read the content of the prompt configuration file
prompt_text=$(cat "$prompt_config_dir/$prompt_config_file")

# Define the save directory (profile configuration)
saves_dir="./$saves_dir"

# Define and create a custom subfolder (profile configuration)
custom_dir="${saves_dir}/${custom_subfolder}"

# Generate a current timestamp for use in naming (profile configuration timestamp_as_dir)
timestamp=$(date +"%Y%m%d%H%M%S")

# Choose whether to create a timestamp-named directory (profile timestamp_as_dir)
if [ "$timestamp_as_dir" = true ]; then
    custom_dir="${custom_dir}/${timestamp}"
fi

# Define files. 1. aggregated text file 2. list of files configured
aggregate="${custom_dir}/${aggr_file_name}.txt"
found_files_list="${custom_dir}/${proj_files_list_name}.txt"

# Ensure the custom directory exists
mkdir -p "$custom_dir"

# Initialize empty files for aggregate and list of found files
> "$aggregate"
> "$found_files_list"

# Construct the find command dynamically with inclusion and exclusion criteria
find_command=( find "$root_dir" -type f )
for ext in "${extensions[@]}"; do
    find_command+=( -iname "*.$ext" )
done
for exclusion in "${exclusions[@]}"; do
    find_command+=( ! -path "$exclusion" )
done

# Use the find command to locate files and prepare them for aggregation
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Check the OS and format paths accordingly for output
        if [ "$OS" == "Linux" ]; then
            echo "$file" >> "$aggregate"
            echo "$file" >> "$found_files_list"
        elif [ "$OS" == "Windows" ]; then
            win_path=$(echo $file | sed 's#/#\\#g' | sed 's#^.\{1\}#C:#')
            echo "//${win_path}" >> "$aggregate"
            echo "$win_path" >> "$found_files_list"
        else
            echo "Unsupported OS: $OS"
            exit 1
        fi
        # Add the contents of the file and separators to the aggregate file
        cat "$file" >> "$aggregate"
        echo -e "\n\n\n" >> "$aggregate"
    else
        echo "Error: File not found - $file"
    fi
done < <( "${find_command[@]}" )

# Add a separator to indicate the end of aggregated code
echo -e "===END OF CODE===" >> "$aggregate"

# Notify the user if no files were found for aggregation
if [ ! -s "$found_files_list" ]; then
    echo "WARNING: No files found for aggregation."
fi

# Indicate completion and location of the aggregated file
echo "Aggregation complete. Located: $aggregate"
echo >&2

# If summarization is enabled, call the summarize function on the aggregated file
if [ "$summarization" = true ]; then
    if [ -s "$aggregate" ]; then
        aggregate_content=$(<"$aggregate")
        summary_file="${custom_dir}/${summ_file_name}.txt"
        summary=$(summarize_with_prompt "$aggregate_content" "$prompt_text" "$summary_file" "$stream_mode")
        echo >&2
        echo "Summary saved to $summary_file"
    else
        echo "Aggregate file is empty or does not exist."
    fi
else
    echo "Summarization OFF, No OpenAI Summary."
fi