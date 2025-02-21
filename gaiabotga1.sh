#!/bin/bash

# Function to handle the API request
send_request() {
    local message="$1"
    local api_key="$2"
    local api_url="$3"

    while true; do
        # Prepare the JSON payload
        json_data=$(cat <<EOF
{
    "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "$message"}
    ]
}
EOF
        )

        # Send the request using curl and capture both the response and status code
        response=$(curl -s -w "\n%{http_code}" -X POST "$api_url" \
            -H "Authorization: Bearer $api_key" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -d "$json_data")

        # Extract the HTTP status code from the response
        http_status=$(echo "$response" | tail -n 1)
        body=$(echo "$response" | head -n -1)

        if [[ "$http_status" -eq 200 ]]; then
            # Check if the response is valid JSON
            echo "$body" | jq . > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                # Print the question and response content
                echo "✅ [SUCCESS] API: $api_url | Message: '$message'"

                # Extract the response message from the JSON
                response_message=$(echo "$body" | jq -r '.choices[0].message.content')
                
                # Print both the question and the response
                echo "Question: $message"
                echo "Response: $response_message"
                break  # Exit loop if request was successful
            else
                echo "⚠️ [ERROR] Invalid JSON response! API: $api_url"
                echo "Response Text: $body"
            fi
        else
            echo "⚠️ [ERROR] API: $api_url | Status: $http_status | Retrying..."
            sleep 2
        fi
    done
}

# Define a list of predefined messages
user_messages=(
    "What is 8 + 5?"
    "What is 12 - 7?"
    "What is 6 × 4?"
    "What is 20 ÷ 5?"
    "What is 15 + 9?"
    "What is 50 - 25?"
    "What is 9 × 3?"
    "What is 36 ÷ 6?"
    "What is 7 + 8?"
    "What is 14 - 6?"
    "What is 5 × 7?"
    "What is 81 ÷ 9?"
    "What is 25 + 17?"
    "What is 60 - 32?"
    "What is 11 × 6?"
    "What is 100 ÷ 20?"
    "What is 19 + 4?"
    "What is 45 - 18?"
    "What is 8 × 9?"
    "What is 72 ÷ 8?"
    "What is 13 + 29?"
    "What is 90 - 44?"
    "What is 4 × 12?"
    "What is 144 ÷ 12?"
    "What is 33 + 27?"
    "What is 81 - 39?"
    "What is 7 × 11?"
    "What is 225 ÷ 15?"
    "What is 56 + 14?"
    "What is 98 - 56?"
)

# Ask the user to input API Key and Domain URL
echo -n "Enter your API Key: "
read api_key
echo -n "Enter the Domain URL: "
read api_url

# Exit if the API Key or URL is empty
if [ -z "$api_key" ] || [ -z "$api_url" ]; then
    echo "Error: Both API Key and Domain URL are required!"
    exit 1
fi

# Set number of threads to 1 (default)
num_threads=1
echo "✅ Using 1 thread..."

# Function to run the single thread
start_thread() {
    while true; do
        # Pick a random message from the predefined list
        random_message="${user_messages[$RANDOM % ${#user_messages[@]}]}"
        send_request "$random_message" "$api_key" "$api_url"
    done
}

# Start the single thread
start_thread &

# Wait for the thread to finish (this will run indefinitely)
wait

# Graceful exit handling (SIGINT, SIGTERM)
trap "echo -e '\n🛑 Process terminated. Exiting gracefully...'; exit 0" SIGINT SIGTERM
