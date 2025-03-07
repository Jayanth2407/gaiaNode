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
    "What do you wear on your head when riding a bike?"
    "Which is the smallest country in the world by land area?"
    "What is the chemical symbol for gold?"
    "Who was the first President of the United States?"
    "Which planet has the most moons in our solar system?"
    "What is the hardest natural substance on Earth?"
    "Which ocean is the largest by surface area?"
    "Who wrote the play Romeo and Juliet?"
    "What is the national currency of the United Kingdom?"
    "Which element is necessary for breathing and survival?"
    "What is the tallest mountain in the world?"
    "Which is the largest desert in the world?"
    "Who painted the famous artwork Mona Lisa?"
    "What is the capital of Australia?"
    "Which gas is most abundant in Earth's atmosphere?"
    "Who discovered penicillin?"
    "Which continent has the most countries?"
    "What is the national flower of India?"
    "How many bones are there in the adult human body?"
    "Which bird is known for its ability to mimic human speech?"
    "What is the currency of Japan?"
    "Which is the longest wall in the world?"
    "What is the main ingredient in traditional Japanese miso soup?"
    "Which is the only planet that rotates on its side?"
    "What is the name of the fairy tale character who leaves a glass slipper behind at a royal ball?"
    "Who invented the light bulb?"
    "Which country is famous for the Great Pyramids of Giza?"
    "What is the chemical formula of water?"
    "What is the fastest land animal in the world?"
    "Who is known as the 'Father of Computers'?"
    "Which two colors are on the flag of Canada?"
    "Which planet is the hottest in the solar system?"
    "Who wrote the famous book The Origin of Species?"
    "What is the main language spoken in Brazil?"
    "Which country is known as the Land of the Rising Sun?"
    "What is the longest railway in the world?"
    "Which element is represented by the symbol 'O' on the periodic table?"
    "Which organ in the human body produces insulin?"
    "What is the deepest ocean in the world?"
    "Who was the first woman to win a Nobel Prize?"
    "Which sport is played at Wimbledon?"
    "Why do leaves change color in autumn?"
    "What is the greenhouse effect and why is it important?"
    "How do airplanes stay in the air despite their weight?"
    "Why do we have different time zones around the world?"
    "What causes tides in the ocean?"
    "How does a rainbow form in the sky?"
    "What is the purpose of the United Nations?"
    "How does a compass work to show direction?"
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

# Ask the user to input the number of threads
echo -n "Enter the number of threads to run: "
read num_threads

# Validate the number of threads
if ! [[ "$num_threads" =~ ^[0-9]+$ ]]; then
    echo "Error: Number of threads must be a positive integer!"
    exit 1
fi

echo "✅ Using $num_threads threads..."

# Function to run a single thread
start_thread() {
    while true; do
        # Pick a random message from the predefined list
        random_message="${user_messages[$RANDOM % ${#user_messages[@]}]}"
        send_request "$random_message" "$api_key" "$api_url"
        # Add a small delay to avoid overwhelming the API
        sleep 1
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
