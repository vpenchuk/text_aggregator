#!/bin/bash

summarize_with_prompt() {
    local file_content=$1
    local prompt_text=$2
    local summary_filename=$3
    local stream_mode=$4
    local openai_api_key=$OPENAI_API_KEY
    local openai_endpoint="https://api.openai.com/v1/chat/completions"

    # Create the JSON payload directly from variables
    local json_payload
    json_payload=$(jq -n \
        --arg prompt "$prompt_text" \
        --arg file_content "$file_content" \
        --argjson stream "$stream_mode" \
        '{
            model: "gpt-4-1106-preview",
            stream: $stream,
            messages: [
                {"role": "system", "content": $prompt},
                {"role": "user", "content": $file_content}
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
        local line clean_line content finish_reason

        while IFS= read -r line; do
            # Remove "data: " prefix before processing the JSON
            clean_line=$(echo "$line" | sed 's/^data: //')

            # Extract "content" and "finish_reason" using jq, but ignore stderr output
            content=$(echo "$clean_line" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
            finish_reason=$(echo "$clean_line" | jq -r '.choices[0].finish_reason' 2>/dev/null)

            # Check if content is non-empty before appending
            if [[ -n "$content" ]]; then
                # Output to console, handling new lines
                if [[ "$content" == $'\n' ]]; then
                    echo "$content" >&2
                else
                    echo -n "$content" >&2
                fi
                # Append to file, handling new lines
                if [[ "$content" == $'\n' ]]; then
                    echo "$content" >>"$summary_filename"
                else
                    echo -n "$content" >>"$summary_filename"
                fi
            fi

            # Check for a non-null finish_reason
            if [[ "$finish_reason" != "null" ]] && [[ -n "$finish_reason" ]]; then
                echo >&2
                echo >&2
                echo "Finish reason: $finish_reason" >&2
                break
            fi
        done
    }

    # Make API request and handle the response
    if [[ "$stream_mode" == "true" ]]; then
        echo "API responses (streaming):" >&2
        perform_curl | handle_stream_response
    else
        local summary_response
        summary_response=$(perform_curl)

        local summary=$(jq -er '.choices[0].message.content // empty' <<<"$summary_response")
        if [[ -n "$summary" ]]; then
            echo "$summary" | tee "$summary_filename" >&2
        else
            echo "Error: No summary content received from OpenAI."
            return 1
        fi
    fi

    echo "Summary saved to $summary_filename"
}

export -f summarize_with_prompt # Export function if running in a subshell
