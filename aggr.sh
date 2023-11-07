#!/bin/bash

# Load the configuration
source config.sh

# Saves directory and custom subfolder path
saves_dir="./saves"
custom_dir="${saves_dir}/${custom_subfolder}"

# Current timestamp for the saved file name
timestamp=$(date +"%Y%m%d%H%M%S")

# New summary file name from configuration, with timestamp and extension
aggregate="${custom_dir}/${output_file_base_name}_${timestamp}.txt"

# Check and create custom subdirectory within saves if not exists
mkdir -p "$custom_dir"

# Empty the aggregate file if it exists or create a new one
> "$aggregate"

# Construct the find command
find_command="find \"$root_dir\" -type f"

# Add inclusion patterns for file extensions
for ext in "${extensions[@]}"; do
    find_command+=" \( -iname \"*.$ext\" \)"
done

# Add exclusion patterns for directories
for exclusion in "${exclusions[@]}"; do
    find_command+=" ! -path \"$exclusion\""
done

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

echo "Aggregation complete. Check $aggregate for the combined contents."