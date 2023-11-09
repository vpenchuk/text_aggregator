#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

# Check if the .host file exists and load it
if [ -f .host ]; then
    OS=$(<.host)
else
    echo "Can't start: .host file not found"
    exit 1
fi

# Define directories for profile and prompt configuration files
profile_config_dir="./configs/profiles"
prompt_config_dir="./configs/prompts"

# Define default configuration filenames
default_profile_config="default-profile"
default_prompt_config="default-prompt"

# Assign profile and prompt config filenames based on script arguments or defaults
profile_config_file="${1:-$default_profile_config}.sh"
prompt_config_file="${2:-$default_prompt_config}.txt"

# Verify existence of profile configuration file and load it
if [ ! -f "$profile_config_dir/$profile_config_file" ]; then
    echo "Profile configuration file not found: $profile_config_dir/$profile_config_file"
    exit 1
fi

# Verify existence of prompt configuration file
if [ ! -f "$prompt_config_dir/$prompt_config_file" ]; then
    echo "Prompt configuration file not found: $prompt_config_dir/$prompt_config_file"
    exit 1
fi

# Import the profile configuration
source "$profile_config_dir/$profile_config_file"

# Read the content of the prompt configuration file
prompt_text=$(cat "$prompt_config_dir/$prompt_config_file")

# Define the save directory (profile configuration)
saves_dir="./$saves_dir"

# Define and create a custom subfolder (profile configuration)
custom_dir="${saves_dir}/${custom_subfolder}"
summaries_dir="${custom_dir}/summaries"