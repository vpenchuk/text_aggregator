echo >&2

# Check for the --list-extensions argument immediately
if [[ "$3" == "--list-extensions" ]]; then
    # If found, source the app_config.sh to ensure environment setup
    source configs/app_config.sh
    # Then, source aggr.sh where the list_file_extensions function is defined
    source aggr.sh
    echo "running the list_file_extensions function on root_dir: $root_dir"
    # Call the list_file_extensions function with the root_dir variable
    list_file_extensions "$root_dir"
    # Exit the script after listing the extensions to prevent further processing
    exit 0
fi


# If not a special argument, proceed with sourcing and running the normal process

# Source the config.sh script
source configs/app_config.sh

first_arg=$1

# Depending on the OS, run the appropriate script and pass the arguments along
if [[ $OS = "Linux" ]]; then
    echo "Detected Linux, using bash"
    bash aggr.sh "$first_arg"
elif [[ $OS = "Windows" ]]; then
    echo "Detected Windows, using sh"
    sh aggr.sh "$first_arg"
else
    echo "Unsupported OS detected: $OS"
    exit 2
fi

echo "===END OF CONSOLE LOGS==="
echo "Task: Update the code to resolve the issues in the console logs"
