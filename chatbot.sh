#!/bin/bash

# Function to check if NVIDIA CUDA or GPU is present
check_cuda() {
    if command -v nvcc &> /dev/null || command -v nvidia-smi &> /dev/null; then
        echo "✅ NVIDIA GPU with CUDA detected."
        return 0  # CUDA is present
    else
        echo "❌ NVIDIA GPU Not Found."
        return 1  # CUDA is not present
    fi
}

# Function to check if the system is a VPS, Laptop, or Desktop
check_system_type() {
    vps_type=$(systemd-detect-virt)
    if echo "$vps_type" | grep -qiE "kvm|qemu|vmware|xen|lxc"; then
        echo "✅ This is a VPS."
        return 0  # VPS
    elif ls /sys/class/power_supply/ | grep -q "^BAT[0-9]"; then
        echo "✅ This is a Laptop."
        return 1  # Laptop
    else
        echo "✅ This is a Desktop."
        return 2  # Desktop
    fi
}

# Function to set the API URL based on system type and CUDA presence
set_api_url() {
    check_system_type
    system_type=$?

    check_cuda
    cuda_present=$?

    if [ "$system_type" -eq 0 ]; then
        # VPS
        API_URL="https://hashtag.gaia.domains/v1/chat/completions"
        API_NAME="Hyper"
    elif [ "$system_type" -eq 1 ]; then
        # Laptop
        if [ "$cuda_present" -eq 0 ]; then
            API_URL="https://hashtag.gaia.domains/v1/chat/completions"
            API_NAME="Soneium"
        else
            API_URL="https://hashtag.gaia.domains/v1/chat/completions"
            API_NAME="Hyper"
        fi
    elif [ "$system_type" -eq 2 ]; then
        # Desktop
        if [ "$cuda_present" -eq 0 ]; then
            API_URL="https://hashtag.gaia.domains/v1/chat/completions"
            API_NAME="Gadao"
        else
            API_URL="https://hashtag.gaia.domains/v1/chat/completions"
            API_NAME="Hyper"
        fi
    fi

    echo "🔗 Using API: ($API_NAME)"
}

# Set the API URL based on system type and CUDA presence
set_api_url

# Check if jq is installed, and if not, install it
if ! command -v jq &> /dev/null; then
    echo "❌ jq not found. Installing jq..."
    sudo apt update && sudo apt install jq -y
    if [ $? -eq 0 ]; then
        echo "✅ jq installed successfully!"
    else
        echo "❌ Failed to install jq. Please install jq manually and re-run the script."
        exit 1
    fi
else
    echo "✅ jq is already installed."
fi

# Function to get a random general question based on the API URL
generate_random_general_question() {
    if [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
general_questions=(
    "What is the capital of France?"
    "Who wrote 'Romeo and Juliet'?"
    "What is the largest planet in the solar system?"
    "What is the chemical symbol for water?"
    "Who painted the Mona Lisa?"
    "What is the smallest prime number?"
    "What is the square root of 64?"
    "What is the currency of Japan?"
    "Who invented the telephone?"
    "What is the longest river in the world?"
    "What is the freezing point of water in Celsius?"
    "What is the main gas found in Earth's atmosphere?"
    "Who was the first president of the United States?"
    "What is the capital of Australia?"
    "What is the largest mammal in the world?"
    "What is the chemical symbol for gold?"
    "Who discovered gravity?"
    "What is the capital of Canada?"
    "What is the smallest continent by land area?"
    "What is the capital of Italy?"
    "What is the largest ocean on Earth?"
    "What is the chemical symbol for oxygen?"
    "Who wrote 'Hamlet'?"
    "What is the capital of Germany?"
    "What is the fastest land animal?"
    "What is the capital of Brazil?"
    "What is the chemical symbol for carbon?"
    "Who was the first man to walk on the moon?"
    "What is the capital of China?"
    "What is the tallest mountain in the world?"
    "Who discovered penicillin?"
    "What is the largest country by land area?"
    "Who wrote 'Pride and Prejudice'?"
    "What is the smallest country in the world?"
    "Who discovered electricity?"
    "What is the largest bird in the world?"
    "Who wrote 'War and Peace'?"
    "What is the largest lake in the world?"
    "Who discovered America?"
    "What is the largest island in the world?"
    "Who discovered the theory of relativity?"
    "What is the largest reptile in the world?"
    "Who wrote '1984'?"
    "What is the largest fish in the world?"
    "Who discovered the structure of DNA?"
    "Who wrote 'The Divine Comedy'?"
    "What is the largest marsupial in the world?"
    "Who discovered the electron?"
    "Who wrote 'The Republic'?"
    "Who discovered the proton?"
)
    elif [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
        general_questions=(
            "Who is the current President of the United States?"
            "What is the capital of Japan?"
            "Which planet is known as the Red Planet?"
            "Who wrote 'To Kill a Mockingbird'?"
            "What is the largest ocean on Earth?"
            "Which country has the most population?"
            "What is the fastest land animal?"
            "Who discovered gravity?"
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
    elif [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
        general_questions=(
            "Who is the current President of the United States?"
            "What is the capital of Japan?"
            "Which planet is known as the Red Planet?"
            "Who wrote 'To Kill a Mockingbird'?"
            "What is the largest ocean on Earth?"
            "Which country has the most population?"
            "What is the fastest land animal?"
            "Who discovered gravity?"
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
    fi

    echo "${general_questions[$RANDOM % ${#general_questions[@]}]}"
}

# Function to handle the API request
send_request() {
    local message="$1"
    local api_key="$2"

    echo "📬 Sending Question to $API_NAME: $message"

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

    # Extract the 'content' from the JSON response using jq (Suppress errors)
    response_message=$(echo "$body" | jq -r '.choices[0].message.content' 2>/dev/null)

    if [[ "$http_status" -eq 200 ]]; then
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
        sleep 0
    fi

    # Set sleep time based on API URL
    if [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
        echo "⏳ Sleeping for 2 seconds (hyper API)..."
        sleep 2
    elif [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
        echo "⏳ Sleeping for 2 seconds (soneium API)..."
        sleep 2
    elif [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
        echo "⏳ No sleep for gadao API..."
        sleep 0
    fi
}

# Asking for API Key (loops until a valid key is provided)
while true; do
    echo -n "Enter your API Key: "
    read -r api_key

    if [ -z "$api_key" ]; then
        echo "❌ Error: API Key is required!"
        echo "🔄 Restarting the installer..."

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

# Display thread information
echo "✅ Using 1 thread..."
echo "⏳ Waiting 30 seconds before sending the first request..."
sleep 4

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
done
