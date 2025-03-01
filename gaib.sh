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
    "What is 1 + 1? Explain step by step."
    "What is 2 + 2? Can you describe the process?"
    "What is 3 + 1? Show your reasoning."
    "What is 4 + 2? Explain like I’m five."
    "What is 5 + 3? Break it down in detail."
    "What is 6 + 1? Explain why the answer is correct."
    "What is 7 + 2? Can you write it as a story?"
    "What is 8 + 3? Show the calculation step by step."
    "What is 9 + 1? Explain using real-life examples."
    "What is 10 + 5? Describe the math in words."
    "What is 7 + 5? Explain the logic behind the sum."
    "What is 9 + 6? Describe how you calculate it."
    "What is 11 + 2? Show all the steps."
    "What is 12 + 3? Can you explain thoroughly?"
    "What is 15 + 4? Break down the addition."
    "What is 18 + 2? Explain with examples."
    "What is 2 - 1? Describe the subtraction."
    "What is 4 - 2? Explain the calculation process."
    "What is 5 - 3? Show the steps clearly."
    "What is 6 - 2? Describe the logic behind it."
    "What is 7 - 5? Explain why the result makes sense."
    "What is 8 - 4? Break down the subtraction."
    "What is 9 - 6? Describe how subtraction works."
    "What is 10 - 3? Explain the solution step by step."
    "What is 12 - 7? Show the subtraction in words."
    "What is 15 - 5? Explain with an example."
    "What is 13 - 6? Describe the calculation process."
    "What is 14 - 8? Explain in detail."
    "What is 16 - 9? Show the reasoning."
    "What is 20 - 4? Describe the math logic."
    "What is 22 - 10? Break it down step by step."
    "What is 25 - 5? Explain why the result is correct."
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

# Set number of threads (default to 5, but you can adjust this)
num_threads=4
echo "✅ Using $num_threads threads..."

# Function to run a single thread
start_thread() {
    while true; do
        # Pick a random message from the predefined list
        random_message="${user_messages[$RANDOM % ${#user_messages[@]}]}"
        send_request "$random_message" "$api_key" "$api_url"
    done
}

# Start multiple threads
for ((i=1; i<=num_threads; i++)); do
    start_thread &
done

# Wait for all threads to finish (this will run indefinitely)
wait

# Graceful exit handling (SIGINT, SIGTERM)
trap "echo -e '\n🛑 Process terminated. Exiting gracefully...'; exit 0" SIGINT SIGTERM
