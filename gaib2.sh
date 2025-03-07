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
    "What is 1 + 1"
    "What is 2 + 2"
    "What is 3 + 1"
    "What is 4 + 2"
    "What is 5 + 3"
    "What is 6 + 1"
    "What is 7 + 2"
    "What is 8 + 3"
    "What is 9 + 1"
    "What is 10 + 5"
    "What is 7 + 5"
    "What is 9 + 6"
    "What is 5 + 2"
    "What is 6 + 3"
    "What is 7 + 4"
    "What is 5 + 2"
    "What is 2 + 1"
    "What is 4 + 2"
    "What is 5 + 3"
    "What is 6 + 2"
    "What is 7 + 5"
    "What is 8 + 4"
    "What is 9 - 6"
    "What is 1 + 3"
    "What is 1 + 7"
    "What is 1 + 5"
    "What is 2 + 1"
    "What is 2 + 2"
    "What is 2 + 3"
    "What is 2 + 1"
    "What is 3 + 2"
    "What is 3 + 3"
    "What is 3 + 1"
    "What is 1 + 6"
    "What is 1 + 8"
    "What is 1 + 9"
    "What is 2 + 4"
    "What is 2 + 7"
    "What is 2 + 5"
        )
    elif [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
        general_questions=(
    
    "What is 1 + 1"
    "What is 2 + 2"
    "What is 3 + 1"
    "What is 4 + 2"
    "What is 5 + 3"
    "What is 6 + 1"
    "What is 7 + 2"
    "What is 8 + 3"
    "What is 9 + 1"
    "What is 10 + 5"
    "What is 7 + 5"
    "What is 9 + 6"
    "What is 5 + 2"
    "What is 6 + 3"
    "What is 7 + 4"
    "What is 5 + 2"
    "What is 2 + 1"
    "What is 4 + 2"
    "What is 5 + 3"
    "What is 6 + 2"
    "What is 7 + 5"
    "What is 8 + 4"
    "What is 9 - 6"
    "What is 1 + 3"
    "What is 1 + 7"
    "What is 1 + 5"
    "What is 2 + 1"
    "What is 2 + 2"
    "What is 2 + 3"
    "What is 2 + 1"
    "What is 3 + 2"
    "What is 3 + 3"
    "What is 3 + 1"
    "What is 1 + 6"
    "What is 1 + 8"
    "What is 1 + 9"
    "What is 2 + 4"
    "What is 2 + 7"
    "What is 2 + 5"
        )
    elif [[ "$API_URL" == "https://hashtag.gaia.domains/v1/chat/completions" ]]; then
        general_questions=(
    "What is 1 + 1"
    "What is 2 + 2"
    "What is 3 + 1"
    "What is 4 + 2"
    "What is 5 + 3"
    "What is 6 + 1"
    "What is 7 + 2"
    "What is 8 + 3"
    "What is 9 + 1"
    "What is 10 + 5"
    "What is 7 + 5"
    "What is 9 + 6"
    "What is 5 + 2"
    "What is 6 + 3"
    "What is 7 + 4"
    "What is 5 + 2"
    "What is 2 + 1"
    "What is 4 + 2"
    "What is 5 + 3"
    "What is 6 + 2"
    "What is 7 + 5"
    "What is 8 + 4"
    "What is 9 - 6"
    "What is 1 + 3"
    "What is 1 + 7"
    "What is 1 + 5"
    "What is 2 + 1"
    "What is 2 + 2"
    "What is 2 + 3"
    "What is 2 + 1"
    "What is 3 + 2"
    "What is 3 + 3"
    "What is 3 + 1"
    "What is 1 + 6"
    "What is 1 + 8"
    "What is 1 + 9"
    "What is 2 + 4"
    "What is 2 + 7"
    "What is 2 + 5"
        )
    fi

    echo "${general_questions[$RANDOM % ${#general_questions[@]}]}"
}

# Function to handle the API request
send_request() {
    local message="$1"
    local api_key="$2"
    local key_name="$3"

    echo "📬 Sending Question to $API_NAME using key: $key_name"
    echo "📝 Question: $message"

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
            echo "✅ [SUCCESS] Response Received!"
            echo "💬 Response: $response_message"
        fi
    else
        echo "⚠️ [ERROR] API request failed | Status: $http_status | Retrying."
        sleep 2
    fi
}

# Directory for API keys
API_KEY_DIR="$HOME/gaianet"
mkdir -p "$API_KEY_DIR"

# Function to load existing API keys
load_existing_keys() {
    API_KEY_LIST=($(ls "$API_KEY_DIR" 2>/dev/null | grep '^apikey_'))
    if [ ${#API_KEY_LIST[@]} -eq 0 ]; then
        echo "❌ No existing API keys found."
        return 1
    else
        echo "🔍 Detected existing API keys:"
        for i in "${!API_KEY_LIST[@]}"; do
            echo "$((i+1))) ${API_KEY_LIST[$i]}"
        done
        return 0
    fi
}

# Function to add a new API key
add_new_key() {
    echo -n "Enter your API Key: "
    read -r api_key

    if [ -z "$api_key" ]; then
        echo "❌ Error: API Key is required!"
        return 1
    fi

    while true; do
        echo -n "Enter a name to save this key (no spaces): "
        read -r key_name
        key_name=$(echo "$key_name" | tr -d ' ')  # Remove spaces

        if [ -z "$key_name" ]; then
            echo "❌ Error: Name cannot be empty!"
        elif [ -f "$API_KEY_DIR/apikey_$key_name" ]; then
            echo "⚠️  A key with this name already exists! Choose a different name."
        else
            echo "$api_key" > "$API_KEY_DIR/apikey_$key_name"
            chmod 600 "$API_KEY_DIR/apikey_$key_name"  # Secure the key file
            echo "✅ API Key saved as 'apikey_$key_name'"
            break
        fi
    done
}

# Main Menu
while true; do
    echo "📂 API Key Management"
    echo "1) Load existing API keys"
    echo "2) Add a new API key"
    echo "3) Start sending requests"
    echo "4) Exit"
    echo -n "👉 Choose an option (1-4): "
    read -r choice

    case "$choice" in
        1)
            load_existing_keys
            ;;
        2)
            add_new_key
            ;;
        3)
            if [ ${#API_KEY_LIST[@]} -eq 0 ]; then
                echo "❌ No API keys loaded. Please add or load keys first."
            else
                break  # Exit the menu and start sending requests
            fi
            ;;
        4)
            echo "🛑 Exiting..."
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please try again."
            ;;
    esac
done

# Ask for duration
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

# Main Loop
start_time=$(date +%s)
while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    if [[ "$elapsed" -ge "$max_duration" ]]; then
        echo "🛑 Time limit reached ($bot_hours hours). Exiting..."
        exit 0
    fi

    random_message=$(generate_random_general_question)

    # Send requests using all API keys in parallel
    for key_file in "${API_KEY_LIST[@]}"; do
        api_key=$(cat "$API_KEY_DIR/$key_file")
        send_request "$random_message" "$api_key" "$key_file" &
    done

    # Wait for all background processes to finish
    wait

    # Sleep before the next batch of requests
    sleep 1
done
