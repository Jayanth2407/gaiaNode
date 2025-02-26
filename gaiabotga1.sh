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
    "Explain what 1 + 1 equals and why?"
"Explain why the sky is blue?"
"Explain what comes after 3 and why it follows?"
"Explain the significance of the first letter of the alphabet?"
"Explain what sound a dog makes and why dogs bark?"
"Explain why Paris is the capital of France and its historical importance?"
"Explain how adding 2 + 2 results in 4, with examples?"
"Explain the concept of hot and cold, and what is the opposite of hot?"
"Explain the properties of a circle and what makes it a unique shape?"
"Explain how bees make honey and their role in nature?"
"Explain why cars typically have four wheels and how they work?"
"Explain why grass is green and how photosynthesis works?"
"Explain what makes 2 the smallest prime number and why it matters?"
"Explain what cows drink and the biological need for hydration?"
"Explain the chemical composition of water and why H2O is essential for life?"
"Explain why water freezes at 0°C and how freezing works?"
"Explain the significance of Tokyo as the capital of Japan?"
"Explain why spiders have 8 legs and how it helps them survive?"
"Explain why cats say 'meow' and what it means?"
"Explain how subtraction works, using 5 - 3 as an example?"
"Explain why bananas are yellow and how they ripen?"
"Explain why Mercury is the closest planet to the sun and its characteristics?"
"Explain the main gases in Earth's atmosphere and their roles?"
"Explain why the Pacific Ocean is the largest on Earth and its importance?"
"Explain what currency is and why the U.S. uses the dollar?"
"Explain multiplication through the example of 3 x 3?"
"Explain why cows say 'moo' and how they communicate?"
"Explain what makes 2 the smallest even number and why it matters?"
"Explain why strawberries are red and how their color develops?"
"Explain the shape of a football and why it's designed that way?"
"Explain the significance of Rome as the capital of Italy?"
"Explain the square root of 16 and how square roots work?"
"Explain why cats purr and what it means?"
"Explain division using the example of 10 ÷ 2?"
"Explain why puppies are called baby dogs and how they grow?"
"Explain why Delhi is the capital of India and its history?"
"Explain the chemical symbol for gold and why it’s valuable?"
"Explain the concept of day and night and their opposites?"
"Explain why humans have 10 fingers and how it helps us function?"
"Explain why the sun appears yellow and its role in the solar system?"
"Explain number sequences and what comes after 10?"
"Explain why apples are red or green and how they grow?"
"Explain why Sunday is often considered the first day of the week?"
"Explain subtraction with the example of 20 - 5?"
"Explain why we brush our teeth and how toothpaste works?"
"Explain why Brasília is the capital of Brazil and its architecture?"
"Explain why Jupiter is the largest planet and its key features?"
"Explain why ducks quack and what it signals?"
"Explain why milk is white and how it’s produced?"
"Explain multiplication with the example of 4 x 2?"
"Explain the role of the President of the U.S. and their powers?"
"Explain why Mars is called the Red Planet and what makes it red?"
"Explain who wrote 'To Kill a Mockingbird' and why it’s significant?"
"Explain which country has the most population and why?"
"Explain why the cheetah is the fastest land animal?"
"Explain how Newton discovered gravity and what it means?"
"Explain why dogs have four legs and how it helps them?"
"Explain number sequences and why 5 comes after 4?"
"Explain why we wear shoes and how they protect our feet?"
"Explain why humans have two eyes and how it aids vision?"
"Explain why bananas are curved and how they grow?"
"Explain the importance of drinking water for survival?"
"Explain what Earth is and why it supports life?"
"Explain why we read books and how they expand knowledge?"
"Explain why grass grows and why it’s important for ecosystems?"
"Explain opposites with examples, like up vs down?"
"Explain why bicycles have two wheels and how they balance?"
"Explain why fish live in water and how they breathe?"
"Explain why blackboards are used and how they help learning?"
"Explain why pizzas are round and the science behind their shape?"
"Explain why kittens are called baby cats and how they develop?"
"Explain subtraction through the example of 5 - 2?"
"Explain why we use scissors and how they cut paper?"
"Explain why birds have wings and how they enable flight?"
"Explain why hats keep your head warm in cold weather?"
"Explain why weeks have 7 days and where that comes from?"
"Explain why umbrellas protect us from rain?"
"Explain why ice melts into water and the science behind it?"
"Explain why rabbits have long ears and how it helps them hear?"
"Explain the four seasons and what comes after summer?"
"Explain why cows produce milk and how it nourishes calves?"
"Explain why cherries are red and how fruit ripens?"
"Explain why we sleep in beds and why rest is important?"
"Explain why ducks float and how their feathers stay dry?"
"Explain why we have toes and how they help us balance?"
"Explain why baby chickens are called chicks?"
"Explain why cereal gets soggy in milk?"
"Explain why elephants are bigger than mice?"
"Explain why spoons are curved and how they hold liquid?"
"Explain why octopuses have 8 arms and how they use them?"
"Explain the days of the week and what comes after Monday?"
"Explain why doors have handles and how they work?"
"Explain why penguins live in cold places?"
"Explain why baby horses are called foals?"
"Explain why pencils write and how graphite works?"
"Explain why cars are faster than bicycles?"
"Explain why eyes are used to see and how vision works?"
"Explain why pillows are soft and why we use them?"
"Explain why starfish have arms and how they move?"
"Explain why lemons are sour and what gives them their taste?"
"Explain why birdhouses are built and how they help birds?"
"Explain why chickens live in coops and how it protects them?"
"Explain why giraffes are tall and how it helps them eat?"
"Explain why we comb our hair and how it detangles?"
"Explain why baby sheep are called lambs?"
"Explain why clocks have hands and how they show time?"
"Explain why libraries store books and why they matter?"
"Explain why elephants have trunks and how they use them?"
"Explain why watermelons are green outside and red inside?"
"Explain why TVs display moving images?"
"Explain the difference between big and small?"
"Explain why stars form constellations?"
"Explain why we use spoons to eat soup?"
"Explain why we wash our hands and its importance?"
"Explain why monkeys like bananas?"
"Explain why polar bears live in the Arctic?"
"Explain why baby cows are called calves?"
"Explain what clocks show and why we track time?"
"Explain why we wear raincoats in the rain?"
"Explain why dogs bark and what they communicate?"
"Explain why phones let us talk to people far away?"
"Explain why shampoo cleans hair and how it works?"
"Explain why we use blankets to stay warm?"
"Explain why kangaroos hop and have pouches?"
"Explain why baby ducks are called ducklings?"
"Explain why we tie shoes and how laces hold?"
"Explain why butterflies have wings and how they fly?"
"Explain why sunglasses protect our eyes?"
"Explain why we blow out candles on a birthday cake?"
"Explain why we wear watches to tell time?"
"Explain why tadpoles grow into frogs?"
"Explain why breakfast is called the most important meal?"
"Explain why people yawn when sleepy?"
"Explain why the moon glows at night?"
"Explain why turtles have shells?"
"Explain why soccer balls are round?"
"Explain why baby fish are called fry?"
"Explain why helmets protect your head?"
"Explain why people dance when they hear music?"
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
num_threads=2
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
