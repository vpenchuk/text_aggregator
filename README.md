# Text Aggregator and Summarizer

This repository contains a set of shell scripts designed to aggregate text from a variety of files and provide a way to summarize the aggregated content using OpenAI's API.

## Overview

The primary functionality is to:
- Aggregate text files based on specific configurations (file extensions to be included, strings of paths (directories or files) to be excluded).
- Provide a summary of the aggregated content by sending it to the OpenAI API.

## Prerequisites

- Shell environment (Bash for Linux or sh for Windows)
- `curl` command-line tool to make requests to APIs
- `jq` tool for handling JSON data
- An OpenAI API Key for sumarization

## Installation

To set up the Text Aggregator and Summarizer:

1. Ensure you have installed the prerequisites on your system.
2. Clone this repository to your desired location:

    ```bash
    git clone https://github.com/your-username/text_aggregator.git
    ```

3. Navigate to the cloned directory:

    ```bash
    cd text_aggregator
    ```

4. Create a `.env` file in the root directory with the following content, replacing `your_openai_api_key` with your actual OpenAI API key:

    ```plaintext
    OPENAI_API_KEY=your_openai_api_key
    ```

5. Verify the script execution permissions or add them if needed:

    ```bash
    chmod +x *.sh
    ```

6. Create a `.host` file in the root directory and specify your operating system (`Linux` or `Windows`) inside it.

## Usage

Run the aggregator by executing the `run.sh` script with optional profile and prompt configurations as arguments:

```bash
./run.sh [profile_config_file] [prompt_config_file]
```

If profile or prompt configuration files are not provided, the default ones will be used.

### Configuration Files

Profile and prompt configurations can be created and placed inside the `configs/profiles` and `configs/prompts` directories respectively. Refer to the existing default configurations as a template.

A Profile.sh specifies files, directories, rules, and options/

A Prompt.txt specified the full text to be used for the OpenAI prompt that will be applied to the aggregated files according to the profile.

#### Example profile configuration

```bash
OS=$(<.host)
saves_dir="saves"
custom_subfolder="default_profile"
aggr_file_name="aggregate"
summ_file_name="summary"
summarization=true
stream_mode=true
proj_files_list_name="filespaths"
timestamp_as_dir=false
root_dir="D:\...\...\my_project_root"
extensions=("sh")  # Array of file extensions to include
exclusions=(
    #config files
    "*\app_config.sh"
    "*\default-profile.sh"

    #saves
    "*\saves"
    ) 
```

#### Example prompt configuration

```txt
In a single concise sentence, explain what the following code does:
```

### Output

The scripts will output:

- **Aggregate txt file**: A text file containing the concatenated contents of all found files.
- **Summary txt file**: If summarization is enabled, a summary of the aggregated content is provided.
- **File Paths txt file**: A list of all files/paths that were aggregated in the run.

## The Scripts

- `app_config.sh`: validates files and directories before running.
- `run.sh`: Wrapper script to run the aggregator based on the operating system specified in the `.host` file.
- `openai.sh`: Contains the function to summarize content using OpenAI API.
- `aggr.sh`: Handles aggregation of text files based on configurations and invokes the summarization.

## Contribution

Feel free to fork the repository and submit pull requests with bug fixes or improvements to the scripts.

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Support

If you encounter any problems, please file an issue along with a detailed description.

**Note:** Be mindful of your API usage to avoid unintended charges or exceeding API rate limits. The scripts do not handle API errors extensively, so ensure your `.env` configuration is correct before use.