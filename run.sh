#!/bin/bash
echo >&2

# Get the operating system type from .host file
OS=$(<.host)

# Check if the .env file exists and load it
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

# Here $1 and $2 represent the first and second arguments passed to run.sh
first_arg=$1
second_arg=$2

# Depending on the OS, run the appropriate script and pass the arguments along
if [[ $OS = "Linux" ]]; then
    echo "Detected linux, using bash"
    # use bash
    bash aggr.sh "$first_arg" "$second_arg"
        #echo "Running linux.sh for $OS"
        # Pass the arguments to linux.sh
        #bash linux.sh "$first_arg" "$second_arg"
elif [[ $OS = "Windows" ]]; then
    echo "Detected windows, using sh"
    # use sh
    sh aggr.sh "$first_arg" "$second_arg"
        #echo "Running windows.sh for $OS"
        # Pass the arguments to windows.sh
        #sh windows.sh "$first_arg" "$second_arg"
else
    echo "Unsupported OS detected: $OS"
    exit 2
fi

echo "===END OF CONSOLE LOGS==="
echo "Task: Update the code to resolve the issues in the console logs"

