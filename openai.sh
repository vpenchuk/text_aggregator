summarize_with_prompt() {
    local file_content=$1
    local prompt_text=$2
    local summary_filename=$3  # Add a third parameter to accept the summary filename
    
    local openai_api_key=$OPENAI_API_KEY
    local openai_endpoint="https://api.openai.com/v1/chat/completions"
    
    # Temporary file for the JSON payload
    local json_payload=$(mktemp)
    
    # Temp File for jp slurping
    echo "$file_content" > /tmp/file_content.tmp

    # Reformat / sanitize the prompt + context for JSON API call
    jq -R -s '.' /tmp/file_content.tmp > /tmp/file_content_formatted.tmp

    # Create the JSON payload
    jq -n \
    --arg prompt "$prompt_text" \
    --slurpfile content /tmp/file_content_formatted.tmp \
    '{model: "gpt-4-1106-preview", stream: true, messages: [{"role": "system", "content": $prompt}, {"role": "user", "content": ($content | add)}]}' > "$json_payload"
    
    # Printing the JSON for diagnostic purposes; this can be removed or redirected as needed
    echo "Starting API request with the following payload:" >&2
    cat "$json_payload" >&2
    echo >&2
    
    # clear the previous summary file
    > "$summary_filename"

    curl -s -X POST "$openai_endpoint" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $openai_api_key" \
    --data-binary @"$json_payload" |
    (
        echo "Raw API responses:" >&2
        
        while IFS= read -r line; do
            # Remove "data: " prefix before processing the JSON
            clean_line=$(echo "$line" | sed 's/^data: //g')
            echo "Processed line (cleaned): $clean_line" >&2  # For debugging
            
            # Extract "content" and "finish_reason" using jq, but ignore stderr output
            content=$(echo "$clean_line" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
            finish_reason=$(echo "$clean_line" | jq -r '.choices[0].finish_reason' 2>/dev/null)

            # Check if content is non-empty before appending
            if [[ -n "$content" ]]; then
                echo "$content"
                echo "$content" >> "$summary_filename"
            fi

            # Check for a non-null finish_reason
            if [ "$finish_reason" != "null" ] && [ -n "$finish_reason" ]; then  # Ensure finish_reason is not null or empty
                echo "Finish reason: $finish_reason" >&2
                break
            fi
        done
        echo "Summary saved to $summary_filename"
    )
    
    # Clean up temporary files
    rm "$json_payload" /tmp/file_content.tmp /tmp/file_content_formatted.tmp
}