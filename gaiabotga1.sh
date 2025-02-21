#!/bin/bash

# Function to check if Python is installed and up-to-date
check_python() {
    # Check if Python 3 is installed
    python3 --version &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Python 3 is already installed."
        # Check if it's the latest version
        latest_version=$(curl -s https://www.python.org/doc/versions/ | grep -oP 'Python \K[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
        installed_version=$(python3 --version | awk '{print $2}')
        
        if [ "$installed_version" == "$latest_version" ]; then
            echo "You already have the latest version of Python 3 ($installed_version)."
        else
            echo "You have Python 3 version $installed_version, but the latest version is $latest_version. You may want to update."
        fi
    else
        echo "Python 3 is not installed. Installing now..."
        # Install Python 3 based on system
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt update && sudo apt install python3 python3-pip -y
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install python3
        else
            echo "Unsupported OS for installation. Please install Python manually."
            exit 1
        fi
    fi
}

# Run the Python check function
check_python

# Ask user for API Key and URL
read -p "Enter your API Key: " api_key
read -p "Enter your API URL (e.g., https://gacrypto.gaia.domains/v1/chat/completions): " api_url

# Ask user for the number of threads
read -p "Enter the number of threads you want to use: " num_threads

# Check if valid number of threads is provided
if [[ ! "$num_threads" =~ ^[0-9]+$ ]] || [ "$num_threads" -lt 1 ]; then
  echo "Invalid input. Please enter a positive number for threads."
  exit 1
fi

# Create a temporary Python script
cat <<EOF > temp_script.py
import cloudscraper
import json
import random
import time
import threading

# Define API Key and URL from shell input
api_key = "$api_key"
api_url = "$api_url"

# Define the number of threads from shell input
num_threads = $num_threads

# Reading user messages from message.txt
with open('message.txt', 'r') as file:
    user_messages = [msg.strip() for msg in file.readlines() if msg.strip()] 

if not user_messages:
    print("Error: No messages in message.txt!")
    exit()

# Initializing Cloudscraper
scraper = cloudscraper.create_scraper()

# Function to send requests to the API
def send_request(message):
    while True:
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }

        data = {
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": message}
            ]
        }

        try:
            response = scraper.post(api_url, headers=headers, json=data)

            # Check the status code and ensure the response is not empty
            if response.status_code == 200:
                try:
                    response_json = response.json()
                    print(f"✅ [SUCCESS] API: {api_url} | Message: '{message}'")
                    print(response_json)
                    break  # Exit the loop if successful
                except json.JSONDecodeError:
                    print(f"⚠️ [ERROR] Invalid JSON response! API: {api_url}")
                    print(f"Response Text: {response.text}")
            else:
                print(f"⚠️ [ERROR] API: {api_url} | Status: {response.status_code} | Retrying in 2s...")
                time.sleep(2)

        except Exception as e:
            print(f"❌ [REQUEST FAILED] API: {api_url} | Error: {e} | Retrying in 5s...")
            time.sleep(2)

# Function to run the thread
def start_thread():
    while True:
        random_message = random.choice(user_messages)
        send_request(random_message)

# Starting multi-threading for sending random messages
threads = []
for _ in range(num_threads):
    thread = threading.Thread(target=start_thread, daemon=True)  # Using daemon so it can be stopped with CTRL+C
    threads.append(thread)
    thread.start()

# Waiting for all threads to finish (script will keep running)
for thread in threads:
    thread.join()

print("All requests have been processed.")  # (This will never be reached because of continuous looping)
EOF

# Run the temporary Python script
python3 temp_script.py

# Clean up the temporary Python script
rm temp_script.py
