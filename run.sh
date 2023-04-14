#!/bin/bash

# The list of file paths/names
files=(
  "../chromium-speech2text/background.js"
  "../chromium-speech2text/content.js"
)

# The aggregate file
aggregate="aggregate.txt"

# Empty the aggregate file if it exists or create a new one
> "$aggregate"

# Loop through the list of files
for file in "${files[@]}"; do
  # Check if the file exists
  if [ -f "$file" ]; then
    # Write the file path/name to the aggregate file without the dot
    echo "//$file" >> "$aggregate"
    # Append the file contents to the aggregate file
    cat "$file" >> "$aggregate"
    # Add 3 new lines between each file's content
    echo -e "\n\n\n" >> "$aggregate"
  else
    echo "Error: $file not found."
  fi
done

echo "Aggregation complete. Check $aggregate for the combined contents."