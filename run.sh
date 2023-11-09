#!/bin/bash
echo >&2

# Source the config.sh script
source configs/app_config.sh

# Here $1 and $2 represent the first and second arguments passed to run.sh
first_arg=$1
second_arg=$2

# Depending on the OS, run the appropriate script and pass the arguments along
if [[ $OS = "Linux" ]]; then
    echo "Detected linux, using bash"
    # use bash
    bash aggr.sh "$first_arg" "$second_arg"
elif [[ $OS = "Windows" ]]; then
    echo "Detected windows, using sh"
    # use sh
    sh aggr.sh "$first_arg" "$second_arg"
else
    echo "Unsupported OS detected: $OS"
    exit 2
fi

# useful for easy copy+past with OpenAI code assistance
echo "===END OF CONSOLE LOGS==="
echo "Task: Update the code to resolve the issues in the console logs"

