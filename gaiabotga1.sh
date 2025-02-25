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
    "What color is the sky?"
    "How many legs does a dog have?"
    "What sound does a cat make?"
    "Which number comes after 4?"
    "What is the opposite of 'hot'?"
    "What do you use to brush your teeth?"
    "What is the first letter of the alphabet?"
    "What shape is a football?"
    "How many fingers do humans have?"
    "What is 1 + 1?"
    "What do you wear on your feet?"
    "What animal says 'moo'?"
    "How many eyes does a person have?"
    "What do you call a baby dog?"
    "Which fruit is yellow and curved?"
    "What do you drink when you're thirsty?"
    "What do bees make?"
    "What is the name of our planet?"
    "What do you do with a book?"
    "What color is grass?"
    "What is the opposite of 'up'?"
    "How many wheels does a bicycle have?"
    "Where do fish live?"
    "What do you use to write on a blackboard?"
    "What shape is a pizza?"
    "What do you call a baby cat?"
    "What is 5 minus 2?"
    "What do you use to cut paper?"
    "What is the color of a banana?"
    "What do birds use to fly?"
    "What do you wear on your head to keep warm?"
    "How many days are in a week?"
    "What do you use an umbrella for?"
    "What does ice turn into when it melts?"
    "How many ears does a rabbit have?"
    "Which season comes after summer?"
    "What color is the sun?"
    "What do cows give us to drink?"
    "Which fruit is red and has seeds inside?"
    "What do you do with a bed?"
    "What sound does a duck make?"
    "How many toes do you have?"
    "What do you call a baby chicken?"
    "What do you put on your cereal?"
    "Which is bigger, an elephant or a mouse?"
    "What do you do with a spoon?"
    "How many arms does an octopus have?"
    "What is the color of a strawberry?"
    "Which day comes after Monday?"
    "What do you use to open a door?"
    "What sound does a cow make?"
    "Where do penguins live?"
    "What do you call a baby horse?"
    "What do you use to write on paper?"
    "Which is faster, a car or a bicycle?"
    "How many ears does a human have?"
    "What do you wear on your hands when it’s cold?"
    "What do you use to see things?"
    "What do you do with a pillow?"
    "How many arms does a starfish have?"
    "What is the color of a lemon?"
    "What do you call a house for birds?"
    "Where do chickens live?"
    "Which is taller, a giraffe or a cat?"
    "What do you use to comb your hair?"
    "What do you call a baby sheep?"
    "How many hands does a clock have?"
    "What do you call a place with lots of books?"
    "Which animal has a long trunk?"
    "What is the color of a watermelon?"
    "What do you do with a TV?"
    "What is the opposite of small?"
    "How many sides does a triangle have?"
    "What do you call a group of stars in the sky?"
    "What do you use to eat soup?"
    "What do you use to clean your hands?"
    "What do monkeys love to eat?"
    "Where do polar bears live?"
    "What do you call a baby cow?"
    "What does a clock show?"
    "What do you wear when it’s raining?"
    "What is something that barks?"
    "What do you use to make a phone call?"
    "What do you use to wash your hair?"
    "What do you do with a blanket?"
    "Which animal can hop and has a pouch?"
    "What do you call a baby duck?"
    "What do you use to tie your shoes?"
    "How many wings does a butterfly have?"
    "What do you wear to protect your eyes from the sun?"
    "What do you do with a birthday cake?"
    "What do you wear on your wrist to tell time?"
    "What do you call a baby frog?"
    "What do you eat for breakfast?"
    "What do you do when you’re sleepy?"
    "What is the color of the moon?"
    "How many legs does a spider have?"
    "Where do turtles live?"
    "What do you do with a soccer ball?"
    "What do you call a baby fish?"
    "What do you wear on your head when riding a bike?"
    "What do you do when you hear music?"
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
num_threads=1
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
