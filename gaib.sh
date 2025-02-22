#!/bin/bash

# Function to check if NVIDIA CUDA or GPU is present
check_cuda() {
    if command -v nvcc &> /dev/null || command -v nvidia-smi &> /dev/null; then
        echo "✅ NVIDIA GPU with CUDA detected. Proceeding with execution..."
    else
        echo "❌ NVIDIA GPU Not Found. This Bot is Only for GPU Users."
        echo "Press Enter to go back and Run on GPU Device..."  
        read -r  # Waits for user input

        # Restart installer
        rm -rf GaiaNodeInstallet.sh
        curl -O https://raw.githubusercontent.com/abhiag/Gaianet_installer/main/GaiaNodeInstallet.sh && chmod +x GaiaNodeInstallet.sh && ./GaiaNodeInstallet.sh

        exit 1
    fi
}

# Run the check
check_cuda

# List of general questions
general_questions=(
    "What is 5 + 3?"
    "How much is 7 + 9?"
    "What is the sum of 10 and 15?"
    "If I add 6 to 4, what do I get?"
    "What is 12 + 8?"
    "What is 8 - 3?"
    "How much is 15 - 5?"
    "What is 20 minus 7?"
    "If I subtract 4 from 9, what do I get?"
    "What is the difference between 13 and 6?"
    "What is 4 * 2?"
    "How much is 5 times 3?"
    "What is the product of 7 and 6?"
    "If I multiply 9 by 2, what do I get?"
    "What is 8 multiplied by 4?"
    "What is 10 / 2?"
    "How much is 15 divided by 3?"
    "What is the quotient of 12 divided by 4?"
    "If I divide 18 by 6, what do I get?"
    "What is 20 divided by 5?"
    "What is 14 + 11?"
    "How much is 16 + 5?"
    "What is 24 - 9?"
    "How much is 100 - 75?"
    "What is 6 * 7?"
    "How much is 9 * 8?"
    "What is the result of 3 * 15?"
    "What is 36 / 6?"
    "How much is 50 / 2?"
    "What is 100 / 25?"
    "What is the sum of 17 and 23?"
    "How much is 13 + 22?"
    "What is 21 - 5?"
    "How much is 40 / 8?"
    "What is the product of 12 and 12?"
    "What is 45 divided by 9?"
    "What is 5 + 19?"
    "How much is 27 - 14?"
    "What is 15 * 5?"
    "How much is 81 / 9?"
    "What is 60 + 22?"
    "How much is 72 - 36?"
    "What is 11 * 11?"
    "How much is 56 / 7?"
    "What is 9 + 45?"
)

# Function to get a random general question
generate_random_general_question() {
    echo "${general_questions[$RANDOM % ${#general_questions[@]}]}"
}

# Function to handle the API request
send_request() {
    local message="$1"
    local api_key="$2"

    echo "📬 Sending Question: $message"

    json_data=$(cat <<EOF
{
    "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "$message"}
    ]
}
EOF
    )

    response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
        -H "Authorization: Bearer $api_key" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$json_data")

    http_status=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)

    # Debugging: Print the entire raw response for inspection
    echo "📊 Full Response: $body"

    if [[ "$http_status" -eq 200 ]]; then
        # Extract the 'content' from the JSON response
        response_message=$(echo "$body" | grep -oP '"content":.*?[^\\]",' | sed 's/"content": "//;s/",//')

        # Check if the response is not empty
        if [[ -z "$response_message" ]]; then
            echo "⚠️ Response content is empty!"
        else
            ((success_count++))  # Increment success count
            echo "✅ [SUCCESS] Response $success_count Received!"
            echo "📝 Question: $message"
            echo "💬 Response: $response_message"
        fi
    else
        echo "⚠️ [ERROR] API request failed | Status: $http_status | Retrying..."
        sleep 2
    fi
}

# Asking for API Key (loops until a valid key is provided)
while true; do
    echo -n "Enter your API Key: "
    read -r api_key

    if [ -z "$api_key" ]; then
        echo "❌ Error: API Key is required!"
        echo "🔄 Restarting the installer..."

        # Restart installer
        rm -rf GaiaNodeInstallet.sh
        curl -O https://raw.githubusercontent.com/abhiag/Gaianet_installer/main/GaiaNodeInstallet.sh && chmod +x GaiaNodeInstallet.sh && ./GaiaNodeInstallet.sh

        exit 1
    else
        break  # Exit loop if API key is provided
    fi
done

# Asking for duration
echo -n "⏳ How many hours do you want the bot to run? "
read -r bot_hours

# Convert hours to seconds
if [[ "$bot_hours" =~ ^[0-9]+$ ]]; then
    max_duration=$((bot_hours * 3600))
    echo "🕒 The bot will run for $bot_hours hour(s) ($max_duration seconds)."
else
    echo "⚠️ Invalid input! Please enter a number."
    exit 1
fi

# Hidden API URL (moved to the bottom)
API_URL="https://gacrypto.gaia.domains/v1/chat/completions"

# Display thread information
echo "✅ Using 1 thread..."
echo "⏳ Waiting 30 seconds before sending the first request..."
sleep 30

echo "🚀 Starting requests..."
start_time=$(date +%s)
success_count=0  # Initialize success counter

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    if [[ "$elapsed" -ge "$max_duration" ]]; then
        echo "🛑 Time limit reached ($bot_hours hours). Exiting..."
        echo "📊 Total successful responses: $success_count"
        exit 0
    fi

    random_message=$(generate_random_general_question)
    send_request "$random_message" "$api_key"
    sleep 0
done
