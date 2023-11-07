#!/bin/bash
OS=$(<.host)

#[[ $OS = "Linux" ]] && { PORT_CHECK=$(lsof -i:40120); PID=$(lsof -ti:40120); }
#[[ $OS = "Windows" ]] && { PORT_CHECK=$(netstat -ano | grep "40120" | grep "ESTABLISHED" ); PID=$(netstat -ano | grep "40120" | grep "ESTABLISHED" | awk 'NR==1{ print $5 }'); }


# The list of file paths/names
files=(
    #  "../SuperGPT/app.js"
    #-"../SuperGPT/routes/conversationRoutes.js"
    #-"../SuperGPT/controllers/conversationController.js"

    #-"../SuperGPT/fileStorage.js"
    #  "../SuperGPT/gpt4.js"

    #  "../SuperGPT/frontend/src/ChatList.js"
    #  "../SuperGPT/frontend/src/ChatControls.js"
    #  "../SuperGPT/frontend/src/Chat.js"
    #  "../SuperGPT/frontend/src/ChatInput.js"

    #-"../SuperGPT/models/message.js"
    #-"../SuperGPT/models/conversation.js"

    #-"../SuperGPT/agents/BaseAgent.js"
    #-"../SuperGPT/agents/AgentManager.js"
    #  "../SuperGPT/agents/AgentDriver.js"
    #-"../SuperGPT/agents/ConversationManager.js"
    #-"../SuperGPT/agents/SpecializedAgents/GenericAgent.js"

    #--------------------------------------------------------
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\models\index.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\models\Twitch_Streamers.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\models\Twitch_Streams.js"

    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\index.js"

    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\routes\SearchTwitchID.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\routes\SearchTwitchUsername.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\routes\Twitch_Streamers.js"

    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\Internal_Scripts\Twitch_getStreamerList.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\Internal_Scripts\Twitch_StreamerUpdates.js"

    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\Scraping_Scripts\driver.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\Scraping_Scripts\twitchInsert.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\Scraping_Scripts\twitchScrape.js"

    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\twitch_api\getRateLimit.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\twitch_api\pollLiveIDs.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\twitch_api\pollLiveStreams.js"
    "D:\Development\TheResearchCorp\MyStats.tv\v3\stream-tracker\server\twitch_api\rateLimiter.js"
)

[[ $OS = "Linux" ]] && {
    # The aggregate file
    aggregate="aggregate.txt"

    # Empty the aggregate file if it exists or create a new one
    > "$aggregate"

    # Loop through the list of files
    for file in "${files[@]}"; do
        # Check if the file exists
        if [ -f "$file" ]; then
            # Write the file path/name to the aggregate file without the dot
            echo "//$file" >> "$aggregate"
            # Append the file contents to the aggregate file
            cat "$file" >> "$aggregate"
            # Add 3 new lines between each file's content
            echo -e "\n\n\n" >> "$aggregate"
        else
            echo "Error: $file not found."
        fi
    done

    echo "Aggregation complete. Check $aggregate for the combined contents."
}

[[ $OS = "Windows" ]] && {
    aggregate="summary.txt"

    # Empty the aggregate file if it exists or create a new one
    > "$aggregate"

    # Assuming 'files' is an array, loop through the list of files
    for file in "${files[@]}"; do
        # Check if the file exists
        if [ -f "$file" ]; then
            # Write the file path/name to the aggregate file without the dot
            echo "//$file" >> "$aggregate"
            # Append the file contents to the aggregate file
            cat "$file" >> "$aggregate"
            # Add 3 new lines between each file's content
            echo -e "\n\n\n" >> "$aggregate"
        else
            echo "Error: $file not found."
        fi
    done

    echo "Aggregation complete. Check $aggregate for the combined contents."
}
