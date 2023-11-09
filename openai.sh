#!/bin/bash

summarize_with_prompt() {
    local aggregate_content=$1
    local prompt_text=$2
    local summary_filename=$3
    local stream_mode=$4
    local openai_api_key=$OPENAI_API_KEY
    local openai_endpoint="https://api.openai.com/v1/chat/completions"

    # Create the JSON payload directly from variables
    local json_payload
    json_payload=$(jq -n \
        --arg prompt "$prompt_text" \
        --arg aggregate_content "$aggregate_content" \
        --argjson stream "$stream_mode" \
        '{
            model: "gpt-4-1106-preview",
            stream: $stream,
            messages: [
                {"role": "system", "content": $prompt},
                {"role": "user", "content": $aggregate_content}
            ]
        }')

    # Initialize or clear the summary file
    : >"$summary_filename"

    # Function to perform the curl request
    perform_curl() {
        curl -s -X POST "$openai_endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $openai_api_key" \
            --data-binary @- <<<"$json_payload"
    }

    handle_stream_response() {
    local line clean_line json_content finish_reason content

        while IFS= read -r line; do
            # If the raw line is empty, continue to the next iteration (skip processing)
            [[ -z "$line" ]] && continue

            # Remove "data: " prefix before processing the JSON
            clean_line="${line#data: }"

            # Use jq to extract content properly with newlines preserved
            json_content=$(echo "$clean_line" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)

            if [[ -n "$json_content" ]]; then
                # Remove the quotes around the string and handle newlines properly
                # Using `tee -a` both to append to the file and to display it in the console
                printf "%b" "${json_content}" | tee -a "$summary_filename" >&2
            fi
        done
    }

    # Make API request and handle the response
    if [[ "$stream_mode" == "true" ]]; then
        echo "(streaming...)" >&2
        perform_curl | handle_stream_response
    else
        local summary_response
        echo "API responses (awaiting full response...):" >&2
        summary_response=$(perform_curl)

        local summary=$(jq -er '.choices[0].message.content // empty' <<<"$summary_response")
        if [[ -n "$summary" ]]; then
            echo "$summary" | tee "$summary_filename" >&2
        else
            echo "Error: No summary content received from OpenAI."
            return 1
        fi
    fi
}

export -f summarize_with_prompt # Export function if running in a subshell
