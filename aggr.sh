#!/bin/bash

OS=$(<.host)
aggregate="summary.txt"

# Root directory to start searching from (change to your specific root)
root_dir="D:/Development/TheResearchCorp/MyStats.tv/v3/stream-tracker/server"

# Specify file extensions
extensions=("js")

# Directories to exclude from the search
exclusions=(
    "*node_modules*"
)

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
        echo "//$win_path" >> "$aggregate"
        cat "$file" >> "$aggregate"
        echo -e "\n\n\n" >> "$aggregate"
    else
        echo "Error: $file not found."
    fi
done

echo "Aggregation complete. Check $aggregate for the combined contents."