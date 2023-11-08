summarize_with_prompt() {
    local file_content=$1
    local prompt_text=$2
    
    # Your OpenAI API key should be read from an environment variable
    local openai_api_key=$OPENAI_API_KEY
    
    # API endpoint for OpenAI Chat
    local openai_endpoint="https://api.openai.com/v1/chat/completions"
    
    # Temporary file for the JSON payload
    local json_payload=$(mktemp)
    
    # Temp File for jp slurping
    echo "$file_content" > /tmp/file_content.tmp
    
    # Reformat / sanitize the prompt + context for JSON API call
    jq -R -s '.' /tmp/file_content.tmp > /tmp/file_content_formatted.tmp
    
    #cat /tmp/file_content.tmp
    
    # Create the JSON payload
    jq -n \
    --arg prompt "$prompt_text" \
    --slurpfile content /tmp/file_content_formatted.tmp \
    '{model: "gpt-4-1106-preview", stream: false, messages: [{"role": "system", "content": $prompt}, {"role": "user", "content": ($content | add)}]}' > "$json_payload"
    
    #cat "$json_payload"
    
    # Make the API call and store the response
    local summary_response=$(curl -s -X POST $openai_endpoint \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $openai_api_key" \
    --data-binary @"$json_payload")
    
    # Remove the temporary file
    rm "$json_payload"
    # Remove the temporary file
    rm /tmp/file_content.tmp
    
    
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
    
    echo "$summary"
    
    # Save summary to a file
    local summary_filename
    if [ "$include_timestamp" = true ]; then
        summary_filename="$custom_dir/${summ_file_name}_${timestamp}.txt"
    else
        summary_filename="$custom_dir/${summ_file_name}.txt"
    fi
    
    echo "$summary" > "$summary_filename"
    echo "Summary saved to $summary_filename"
}