#!/bin/bash
# This bash script is designed to aggregate text from files based on configured profiles and prompts,
# and then optionally pass the aggregated content to an OpenAI summarization tool.

# Display a line break for cleaner output
echo >&2

# Import the OpenAI script functions
source openai.sh

# Import the config.sh script
source configs/app_config.sh

# Generate a current timestamp for use in naming (profile configuration timestamp_as_dir)
timestamp=$(date +"%Y%m%d%H%M%S")

# Choose whether to create a timestamp-named directory (profile timestamp_as_dir)
if [ "$timestamp_as_dir" = true ]; then
    custom_dir="${custom_dir}/${timestamp}"
    summaries_dir="${custom_dir}/summaries"
fi

# Ensure the custom directories exists
mkdir -p "$custom_dir"

# Define files: 1. aggregated text file 2. list of files configured
aggregate="${custom_dir}/${aggr_file_name}.txt"
found_files_list="${custom_dir}/${proj_files_list_name}.txt"

# Initialize empty files for aggregate and list of found files
: >"$aggregate"
: >"$found_files_list"

if [ "${summary_mode}" == "individual" ]; then
    echo 'You have selected "individual" mode...'

    # Construct the find command dynamically with inclusion and exclusion criteria
    find_command=(find "$root_dir" -type f)
    for ext in "${extensions[@]}"; do
        find_command+=(-iname "*.$ext")
    done
    for exclusion in "${exclusions[@]}"; do
        find_command+=(! -path "$exclusion")
    done

    # Loop through the found files and perform actions regardless of summarization value
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Check the OS and format paths accordingly for output
            if [ "$OS" == "Linux" ]; then
                echo "$file" >>"$found_files_list"
            elif [ "$OS" == "Windows" ]; then
                win_path=$(echo $file | sed 's#/#\\#g' | sed 's#^.\{1\}#C:#')
                echo "$win_path" >>"$found_files_list"
            else
                echo "Unsupported OS: $OS"
                exit 1
            fi
            # Add the filename and the contents of the file and separators to the aggregate file
            echo "//$file" >>"$aggregate"
            cat "$file" >>"$aggregate"
            echo -e "\n\n\n" >>"$aggregate"
        else
            echo "Error: File not found - $file"
        fi
    done < <("${find_command[@]}")

    # Add a separator to indicate the end of aggregated code
    echo -e "===END OF CODE===" >>"$aggregate"

    # Separate the summarization process
    if [ "$summarization" = true ]; then
        echo '...Generating individual summaries...'

        mkdir -p "${summaries_dir}"

        summary_file="${custom_dir}/${summ_file_name}.txt"
        : >$summary_file

        ((file_counter = 0))
        while IFS= read -r file; do
            ((file_counter++))
            echo "$file_counter"
            if [ -f "$file" ]; then
                # Generate a filename for the individual summary
                base_filename=$(basename -- "$file")
                summary_filename="${summaries_dir}/${base_filename}.summary"

                # Read the content of the file
                file_contents=$(cat "$file")

                # Call the summarize_with_prompt function for each file
                summary=$(summarize_with_prompt "$file_contents" "$prompt_text" "$summary_filename" "$stream_mode" "$summary_file" "$summary_mode")
                #echo "$summary" >>"$summary_file"

                # Output to indicate where the individual summary has been saved
                echo
                echo "~Summary for $base_filename saved to $summary_filename"
                echo
            else
                echo "Error: File not found - $file"
            fi
        done < <("${find_command[@]}")
    else
        echo "Summarization OFF, aggregation of file contents complete."
    fi
elif [ "${summary_mode}" == "aggregate" ]; then
    echo 'You have selected "aggregate"'

    # Construct the find command dynamically with inclusion and exclusion criteria
    find_command=(find "$root_dir" -type f)
    for ext in "${extensions[@]}"; do
        find_command+=(-iname "*.$ext")
    done
    for exclusion in "${exclusions[@]}"; do
        find_command+=(! -path "$exclusion")
    done

    # Use the find command to locate files and prepare them for aggregation
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Check the OS and format paths accordingly for output
            if [ "$OS" == "Linux" ]; then
                echo "$file" >>"$aggregate"
                echo "$file" >>"$found_files_list"
            elif [ "$OS" == "Windows" ]; then
                win_path=$(echo $file | sed 's#/#\\#g' | sed 's#^.\{1\}#C:#')
                echo "//${win_path}" >>"$aggregate"
                echo "$win_path" >>"$found_files_list"
            else
                echo "Unsupported OS: $OS"
                exit 1
            fi
            # Add the contents of the file and separators to the aggregate file
            cat "$file" >>"$aggregate"
            echo -e "\n\n\n" >>"$aggregate"
        else
            echo "Error: File not found - $file"
        fi
    done < <("${find_command[@]}")

    # Add a separator to indicate the end of aggregated code
    echo -e "===END OF CODE===" >>"$aggregate"

    # Notify the user if no files were found for aggregation
    if [ ! -s "$found_files_list" ]; then
        echo "WARNING: No files found for aggregation."
    fi

    # Indicate completion and location of the aggregated file
    echo "Aggregation complete. Located: $aggregate"
    echo >&2

    # If summarization is enabled, call the summarize function on the aggregated file
    if [ "$summarization" = true ]; then
        echo '...Generating individual summary file...'
        if [ -s "$aggregate" ]; then
            aggregate_content=$(<"$aggregate")
            summary_file="${custom_dir}/${summ_file_name}.txt"
            : >$summary_file
            summary_file_basename=$(basename "$summary_file")
            summary_filename="${summaries_dir}/${summary_file_basename}"
            summarize_with_prompt "$aggregate_content" "$prompt_text" "$summary_filename" "$stream_mode" "$summary_file" "$summary_mode"
            #echo >&2
        else
            echo "Aggregate file is empty or does not exist."
        fi
    else
        echo "Summarization OFF, No OpenAI Summary."
    fi
else
    echo "??? summary_mode"
fi
