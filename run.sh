#!/bin/bash

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
    echo "Running linux.sh for $OS"
    # Pass the arguments to linux.sh
    ./linux.sh "$first_arg" "$second_arg"
elif [[ $OS = "Windows" ]]; then
    echo "Running windows.sh for $OS"
    # Pass the arguments to windows.sh
    ./windows.sh "$first_arg" "$second_arg"
else
    echo "Unsupported OS: $OS"
    exit 2
fi
