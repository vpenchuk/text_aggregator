#!/bin/bash
# This bash script is designed to aggregate text from files based on configured profiles and prompts,
# and then optionally pass the aggregated content to an OpenAI summarization tool.

# Display a line break for cleaner output
echo >&2

# Source the OpenAI script functions and configurations
source "./openai.sh"
source configs/app_config.sh

# Helper functions
create_directory() {
    mkdir -p "$1"
}

initialize_file() {
    : >"$1"
}

add_to_file() {
    echo "$2" >>"$1"
}

format_windows_path() {
    local file="$1"
    echo "$file" | sed 's#/#\\#g' | sed 's#^.\{1\}#C:#'
}

check_os_and_format_path() {
    local file="$1"
    if [[ "$OS" == "Linux" ]]; then
        echo "$file"
    elif [[ "$OS" == "Windows" ]]; then
        format_windows_path "$file"
    else
        echo "Unsupported OS: $OS"
        exit 1
    fi
}

# Create the find command to locate files
find_command="find $root_dir -type f"
ext_count=${#extensions[@]}

if [ "$ext_count" -gt 0 ]; then
    find_command+=" \\( "
    for ((i=0; i<ext_count; i++)); do
        find_command+="-iname \"*.${extensions[i]}\""
        if [ $((i + 1)) -lt "$ext_count" ]; then
            find_command+=" -o "
        fi
    done
    find_command+=" \\) "
fi

for exclusion in "${exclusions[@]}"; do
    find_command+=" ! -path \"$exclusion\""
done

# Generate a current timestamp for use in naming
timestamp=$(date +"%Y%m%d%H%M%S")
custom_dir="${saves_dir}/${custom_subfolder}"
summaries_dir="${custom_dir}/summaries"
if [[ "$timestamp_as_dir" == true ]]; then
    custom_dir="${custom_dir}/${timestamp}"
    summaries_dir="${custom_dir}/summaries"
fi

create_directory "$custom_dir"

# Define aggregated text file and list of files configured
aggregate="${custom_dir}/${aggr_file_name}.txt"
found_files_list="${custom_dir}/${proj_files_list_name}.txt"

initialize_file "$aggregate"
initialize_file "$found_files_list"

# Loop through the files based on the find command
((total_files = 0))
while IFS= read -r file; do
    ((total_files++))
    if [[ -f "$file" ]]; then
        formatted_path=$(check_os_and_format_path "$file")
        add_to_file "$found_files_list" "$formatted_path"
        add_to_file "$aggregate" "$formatted_path"
        cat "$file" >> "$aggregate"
        echo -e "\n" >>"$aggregate"
    else
        echo "Error: File not found - $file"
    fi
#done < <("${find_command[@]}")
done < <(eval "$find_command")

# Add a separator to indicate the end of aggregated code
add_to_file "$aggregate" "===END OF CODE==="

# Handle individual summarization mode
process_individual_mode() {
    echo 'You have selected "individual" mode...'
    echo >&2
    if [[ "$summarization" == true ]]; then
        create_directory "${summaries_dir}"

        summary_file="${custom_dir}/${summ_file_name}.txt"
        initialize_file "$summary_file"

        file_counter=0
        while IFS= read -r file; do
            ((file_counter++))
            if [[ -f "$file" ]]; then
                base_filename=$(basename -- "$file")
                summary_filename="${summaries_dir}/${base_filename}.summary"
                file_contents=$(<"$file")
                echo -n "$file_counter of $total_files"
                summarize_with_prompt "$file_contents" "$prompt_text" "$summary_filename" "$stream_mode" "$summary_file" "$summary_mode"

                echo
                echo "~Summary for $base_filename saved to $summary_filename"
                echo

            else
                echo "Error: File not found - $file"
            fi
        done < <("${find_command[@]}")
    else
        echo "Summarization is OFF"
        echo
    fi
}

# Handle aggregate summarization mode
process_aggregate_mode() {
    echo 'You have selected "aggregate"'
    if [[ ! -s "$found_files_list" ]]; then
        echo "WARNING: No files found for aggregation."
    fi

    echo "Aggregation complete. Located: $aggregate"
    echo >&2

    if [[ "$summarization" == true && -s "$aggregate" ]]; then
        echo '...Generating summary file...'
        #create_directory "${summaries_dir}"

        aggregate_content=$(<"$aggregate")
        summary_file="${custom_dir}/${summ_file_name}.txt"
        initialize_file "$summary_file"

        summary_filename="${summaries_dir}/$(basename "$summary_file")"
        #summary_filename_file="${summary_filename}.txt"
        #initialize_file "$summary_filename"

        summarize_with_prompt "$aggregate_content" "$prompt_text" "$summary_filename" "$stream_mode" "$summary_file" "$summary_mode"
        echo >&2
    else
        echo "Summarization is OFF or Aggregate file is empty."
    fi
}

# Process summarization based on mode
if [[ "$summary_mode" == "individual" ]]; then
    process_individual_mode
elif [[ "$summary_mode" == "aggregate" ]]; then
    process_aggregate_mode
else
    echo "Unknown summary_mode: $summary_mode"
    exit 1
fi
