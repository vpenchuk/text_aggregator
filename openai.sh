#!/bin/bash

summarize_with_prompt() {
    local aggregate_content=$1
    local prompt_text=$2
    local summary_filename=$3
    local stream_mode=$4
    local summary_file=$5
    local summary_mode=$6
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

    # Initialize or clear the summary file if not null
    if [ -n "$summary_filename" ]; then
        echo
    else
        : >"$summary_filename"
    fi

    if [ -n "$summary_file" ]; then
        echo
    else
        : >"$summary_file"
    fi

    # Function to perform the curl request
    perform_curl() {
        curl -s -X POST "$openai_endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $openai_api_key" \
            --data-binary @- <<<"$json_payload"
    }

    handle_stream_response() {
        local line clean_line json_content finish_reason content

        printf "%b" "${summary_filename}:" >>"$summary_file"
        printf "\n" >>"$summary_file"
        while IFS= read -r line; do
            # If the raw line is empty, continue to the next iteration (skip processing)
            [[ -z "$line" ]] && continue

            # Remove "data: " prefix before processing the JSON
            clean_line="${line#data: }"
            #echo "$clean_line" >&2

            # Use jq to extract stream's content
            content=$(echo "$clean_line" | jq '.choices[0].delta.content // empty' 2>/dev/null)
            # Use jq to extract content with
            json_content=$(echo "$clean_line" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)

            if [[ -n "$json_content" ]]; then
                # Remove quotation marks from $content
                content_without_quotes=$(echo "$content" | tr -d '"')

                # Always print json_content to the screen
                #echo >&2
                #echo -n "$content" >&2
                #echo -n "$content_without_quotes" >&2
                echo -n "$json_content" >&2
                #echo >&2

                if [[ "$summary_mode" == "individual" ]]; then
                    # Append to the individual summary file if summary_mode is "individual"
                    printf "%s" "$json_content" >>"$summary_filename"
                fi

                # Always append json_content to the main summary file
                printf "%s" "$json_content" >>"$summary_file"

                # Count the number of newline characters in the modified content
                newline_count=$(awk 'BEGIN{RS="\\\\n"}END{print NR-1}' <<<"$content_without_quotes")
                #echo " - Number of newline characters detected: $newline_count" >&2

                # Print a new line for each newline character found
                for ((i = 1; i <= newline_count; i++)); do
                    #echo -n "($i)" >&2
                    echo "" >> "$summary_filename"
                    echo "" >> "$summary_file"
                    echo >&2
                done
            fi
        done
        printf "\n\n" >>"$summary_file"
    }

    # Make API request and handle the response
    if [[ "$stream_mode" == "true" ]]; then
        echo "(streaming...)" >&2
        perform_curl | handle_stream_response "$summary_filename" "$summary_file"
    else
        local summary_response
        echo "API responses (awaiting full response...):" >&2
        summary_response=$(perform_curl)

        local summary=$(jq -er '.choices[0].message.content // empty' <<<"$summary_response")
        if [[ -n "$summary" ]]; then

            if [[ "$summary_mode" == "individual" ]]; then
                # Write to the individual's summary file and display in the console
                echo "$summary" | tee "$summary_filename"
            fi

            # Write to the main summary file & console.
            echo "$summary_filename: " >>"$summary_file"
            echo "$summary" >>"$summary_file"
            echo "$summary" >&2
        else
            echo "Error: No summary content received from OpenAI."
            return 1
        fi
    fi
}

export -f summarize_with_prompt # Export function if running in a subshell
