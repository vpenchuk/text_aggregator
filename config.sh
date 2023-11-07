#!/bin/bash

# Root directory to start searching from (change to your specific root)
root_dir="D:\Development\SideProjects\text_aggregator"

# Specify file extensions
extensions=("sh")

# Directories to exclude from the search
exclusions=(
    "*node_modules*"
)

# Custom subfolder within the saves directory
custom_subfolder="text-aggregator"

# Output file base name
output_file_base_name="new-configs"
