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
   "Who was the first person to set foot on the Moon"
    "What is the capital of Canada"
    "Who wrote the famous play Romeo and Juliet"
    "Which planet is known as the Red Planet"
    "What is the chemical symbol for gold"
    "What does HTML stand for"
    "What is the output of print(2 ** 3) in Python"
    "Which data structure follows the Last In First Out LIFO principle"
    "In JavaScript which keyword is used to declare a constant variable"
    "What does the acronym SQL stand for"
    "Who painted the Mona Lisa"
    "What is the largest ocean on Earth"
    "Which country is known as the Land of the Rising Sun"
    "Who discovered gravity"
    "How many continents are there on Earth"
    "What is the longest river in the world"
    "What is the national currency of Japan"
    "Who was the first President of the United States"
    "What is the smallest planet in the Solar System"
    "Which country gifted the Statue of Liberty to the United States"
    "What is the tallest mountain in the world"
    "Which scientist developed the theory of relativity"
    "What is the main ingredient in traditional sushi"
    "Which language has the most native speakers in the world"
    "How many bones are there in the human body"
    "What is the capital city of Australia"
    "Which animal is known as the King of the Jungle"
    "What is the square root of 64"
    "Which country is famous for the Eiffel Tower"
    "What does the acronym NASA stand for"
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
