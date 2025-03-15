#!/bin/bash

# API keys (defined like general questions, one per line)
API_KEYS=(
    "gaia-OThhNWQ3MGQtM2FiYy00MWNhLWI0ZTYtYTNkNDZlODc0NGJl-YGgaP8e1JS0ZG-Ru"
    "gaia-NzE4YTg0NTMtMTlhNS00ZGY2LWFjZWUtZWFlZWU5ODlhMGVj-gw8155rfaVE4Xfo8"
    "gaia-ZTA1MTQzNWUtYmMwYS00Y2ZkLWI1Y2EtNGFhMDY4NjU5NTY5-VLcbW1iUq0zB-DdA"
    "gaia-NmMyNGVhMTQtYzkzNC00NTlhLTg3NTUtNTVhMWEwNTIzNDVj-FpPRujgNKR7mDCGi"
    "gaia-ZWE1M2E2NjgtMzUxZi00MzlhLWI2Y2QtNTczNTc1OTBlYzJi-f5eOgLEzKr5rXybd"
    "gaia-YjEzMGRlZTEtYThjOS00ODM1LTg1OGMtZmYxZjU1NzM2YTA0-eyxuH75C2QM86pDe"
    "gaia-NmJiMGFlMDItODk3OS00Yzk2LTkwMWYtMDgzY2JhMmY2N2Mz-2FU0MRrReeNQRYYF"
    "gaia-MGQwMjVmNDQtYWJiMy00ZmFlLWI5OGYtNjlhNmVjZTkxYjkw-tQbLQOoAT5v60FBW"
    "gaia-ZTZkYzRhNjctZTRiMi00NDQyLTlhNjgtODdmMWZhMjRmYWE2-R7omTjx0V-05nQbC"
    "gaia-YTgwMTY0NjktODUyYS00OWU1LTg3YTMtOTQ5MDEyZWY3Nzcx-5xbmMfBVGhcY5RxG"
)

# Single API URL
API_URL="https://hashtag.gaia.domains/v1/chat/completions"

# Thread count (can be changed as needed)
THREAD_COUNT=5

# Failure handling
MAX_CONSECUTIVE_FAILURES=3  # Maximum allowed consecutive failures
COOLDOWN_PERIOD=30          # Cooldown period in seconds after max failures

# Function to get a random general question
generate_random_general_question() {
    general_questions=(
        "Why is the Renaissance considered a turning point in history?"
        "How did the Industrial Revolution change the world?"
        "Why is the Great Wall of China historically significant?"
        "What were the main causes of World War I?"
        "How did the printing press impact society?"
        "Why is the moon landing in 1969 considered a major achievement?"
        "What led to the fall of the Roman Empire?"
        "How did the Cold War shape global politics?"
        "Why is the Amazon rainforest important for the planet?"
        "What sound does a cat make?"
        "Which number comes after 4?"
        "What is the opposite of 'hot'?"
        "What do you use to brush your teeth?"
        "What is the first letter of the alphabet?"
        "What shape is a football?"
        "How many fingers do humans have?"
        "How do vaccines work to protect against diseases?"
        "What are black holes, and why are they important in astronomy?"
        "How does climate change affect ecosystems?"
        "Why is the discovery of DNA considered revolutionary?"
        "How did the internet change modern communication?"
        "What role does the United Nations play in global peacekeeping?"
        "Why is the Suez Canal important for global trade?"
        "How did the Magna Carta influence modern democracy?"
        "Why is the water cycle crucial for life on Earth?"
        "What are the main challenges of space exploration?"
        "How did the discovery of electricity transform society?"
        "Why is the number zero important in mathematics?"
        "How is the Fibonacci sequence observed in nature?"
        "Why is the Pythagorean theorem significant in geometry?"
        "How does probability influence real-life decision-making?"
        "What are prime numbers, and why are they important in cryptography?"
        "Why is calculus essential in modern science and engineering?"
        "How does the concept of infinity affect mathematical theories?"
        "What is the significance of Euler’s formula in mathematics?"
        "Why is Pi considered an irrational number, and why is it useful?"
        "How does statistics help in making informed decisions?"
    )

    echo "${general_questions[$RANDOM % ${#general_questions[@]}]}"
}

# Function to handle the API request with retries and exponential backoff
send_request() {
    local message="$1"
    local api_key="$2"
    local retry_count=0
    local max_retries=5
    local initial_delay=1

    while [ $retry_count -lt $max_retries ]; do
        echo "📬 Sending Question using key: ${api_key:0:4}****"  # Mask API key for security
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
            -d "$json_data" --max-time 10)  # Add a timeout to avoid hanging

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
            return 0
        else
            echo "⚠️ [ERROR] API request failed | Status: $http_status | Retrying in $initial_delay seconds..."
            sleep $initial_delay
            retry_count=$((retry_count + 1))
            initial_delay=$((initial_delay * 2))  # Exponential backoff
        fi
    done

    echo "❌ [FATAL] Max retries reached. Giving up."
    return 1
}

# Main Loop
consecutive_failures=0  # Track consecutive failures
api_index=0  # Track the current API index

while true; do
    # Start threads
    for ((i = 1; i <= THREAD_COUNT; i++)); do
        random_message=$(generate_random_general_question)
        
        # Pick 2 APIs in order
        for ((j = 0; j < 2; j++)); do
            api_key="${API_KEYS[$api_index]}"
            send_request "$random_message" "$api_key" &
            
            # Increment and wrap around the API index
            api_index=$(( (api_index + 1) % ${#API_KEYS[@]} ))
        done
    done

    # Wait for all background processes to finish
    wait

    # Check for failures
    if [[ $? -ne 0 ]]; then
        consecutive_failures=$((consecutive_failures + 1))
        echo "⚠️ Consecutive Failures: $consecutive_failures"
    else
        consecutive_failures=0  # Reset on success
    fi

    # If max consecutive failures reached, pause and restart
    if [[ $consecutive_failures -ge $MAX_CONSECUTIVE_FAILURES ]]; then
        echo "🚨 Max consecutive failures reached. Pausing for $COOLDOWN_PERIOD seconds..."
        sleep $COOLDOWN_PERIOD
        consecutive_failures=0  # Reset after cooldown
        echo "🔄 Restarting chatbot..."
    fi

    # Sleep before the next batch of requests
    sleep 1
done
