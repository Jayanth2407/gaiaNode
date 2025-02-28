#!/bin/bash

# Function to handle the API request
send_request() {
    local message="$1"
    local api_key="$2"
    local api_url="https://hashtag.gaia.domains/v1/chat/completions"

    while true; do
        json_data=$(cat <<EOF
{
    "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "$message"}
    ]
}
EOF
        )

        response=$(curl -s -w "\n%{http_code}" -X POST "$api_url" \
            -H "Authorization: Bearer $api_key" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -d "$json_data")

        http_status=$(echo "$response" | tail -n 1)
        body=$(echo "$response" | head -n -1)

        if [[ "$http_status" -eq 200 ]]; then
            echo "$body" | jq . > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "✅ [SUCCESS] API: $api_url | Message: '$message'"
                response_message=$(echo "$body" | jq -r '.choices[0].message.content')
                echo "Question: $message"
                echo "Response: $response_message"
                sleep 10  # Wait for 1 minute before next request
                break
            else
                echo "⚠️ [ERROR] Invalid JSON response! API: $api_url"
                echo "Response Text: $body"
                sleep 10  # Wait for 1 minute before retrying
            fi
        else
            echo "⚠️ [ERROR] API: $api_url | Status: $http_status | Retrying..."
            sleep 10  # Wait for 1 minute before retrying
        fi
    done
}

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

echo -n "Enter your API Key: "
read api_key

if [ -z "$api_key" ]; then
    echo "Error: API Key is required!"
    exit 1
fi

echo "✅ Using fixed domain URL: $api_url"

# Wait for a random time between 1 to 3 minutes before sending the first request
initial_wait=$((60 + RANDOM % 120))
echo "⏳ Waiting for $initial_wait seconds before the first request..."
sleep $initial_wait

start_thread() {
    while true; do
        random_message="${user_messages[$RANDOM % ${#user_messages[@]}]}"
        send_request "$random_message" "$api_key"
    done
}

start_thread &

wait

trap "echo -e '\n🛑 Process terminated. Exiting gracefully...'; exit 0" SIGINT SIGTERM
