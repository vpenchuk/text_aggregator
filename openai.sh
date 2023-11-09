summarize_with_prompt() {
    local file_content=$1
    local prompt_text=$2
    local summary_filename=$3 # Add a third parameter to accept the summary filename
    local stream_mode=$4

    local openai_api_key=$OPENAI_API_KEY
    local openai_endpoint="https://api.openai.com/v1/chat/completions"

    # Temporary file for the JSON payload
    local json_payload=$(mktemp)

    # Temp File for jp slurping
    echo "$file_content" >/tmp/file_content.tmp

    # Reformat / sanitize the prompt + context for JSON API call
    jq -R -s '.' /tmp/file_content.tmp >/tmp/file_content_formatted.tmp

    # Create the JSON payload
    jq -n \
        --arg prompt "$prompt_text" \
        --argjson stream "$stream_mode" \
        --slurpfile content /tmp/file_content_formatted.tmp \
        '{model: "gpt-4-1106-preview", stream: $stream, messages: [{"role": "system", "content": $prompt}, {"role": "user", "content": ($content | add)}]}' >"$json_payload"

    # Printing the JSON for diagnostic purposes; this can be removed or redirected as needed
    echo >&2
    echo "Starting API request with the json_payload" >&2
    #cat "$json_payload" >&2
    echo "Please wait, stream_mode: $stream_mode" >&2
    echo >&2

    # clear the previous summary file
    >"$summary_filename"

    echo "API responses:" >&2
    if [[ "$stream_mode" = true ]]; then
        curl -s -X POST "$openai_endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $openai_api_key" \
            --data-binary @"$json_payload" |
            (

                while IFS= read -r line; do
                    # Remove "data: " prefix before processing the JSON
                    clean_line=$(echo "$line" | sed 's/^data: //g')
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
                    if [ "$finish_reason" != "null" ] && [ -n "$finish_reason" ]; then
                        echo >&2
                        echo >&2
                        echo "Finish reason: $finish_reason" >&2
                        break
                    fi
                done
                echo "Summary saved to $summary_filename"
            )
    elif [[ "$stream_mode" = false ]]; then
        local summary_response=$(curl -s -X POST $openai_endpoint \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $openai_api_key" \
            --data-binary @"$json_payload")

        # Remove the temporary file
        #rm "$json_payload"
        # Remove the temporary file
        #rm /tmp/file_content.tmp

        # Extract the text from the response
        local summary=$(echo "$summary_response" | jq -r '.choices[0].message.content')

        # Check for errors in the response
        if [[ "$summary" == "" || "$summary" == "null" ]]; then
            local error_message=$(echo "$summary_response" | jq -r '.error.message')
            if [[ "$error_message" != "null" ]]; then
                echo "Error from OpenAI: $error_message"
                return 1
            else
                echo "No summary was provided or an unknown error occurred."
                return 1
            fi
        fi

        echo "$summary" >&2

        # Save summary to a file
        local summary_filename
        if [ "$include_timestamp" = true ]; then
            summary_filename="$custom_dir/${summ_file_name}_${timestamp}.txt"
        else
            summary_filename="$custom_dir/${summ_file_name}.txt"
        fi

        echo "$summary" >"$summary_filename"
        echo "Summary saved to $summary_filename"
    else
        echo "whoops"
    fi

    # Clean up temporary files
    rm "$json_payload" /tmp/file_content.tmp /tmp/file_content_formatted.tmp
}
