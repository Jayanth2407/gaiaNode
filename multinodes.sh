#!/bin/bash

# Exit on error and log all output
set -e
trap "echo 'Script interrupted. Exiting...'; exit 1" SIGINT SIGTERM
LOG_FILE="gaia_node_manager.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Display banner
printf "\n"
cat <<EOF

██╗░░██╗░█████╗░░██████╗██╗░░██╗████████╗░█████╗░░██████╗░
██║░░██║██╔══██╗██╔════╝██║░░██║╚══██╔══╝██╔══██╗██╔════╝░
███████║███████║╚█████╗░███████║░░░██║░░░███████║██║░░██╗░
██╔══██║██╔══██║░╚═══██╗██╔══██║░░░██║░░░██╔══██║██║░░╚██╗
██║░░██║██║░░██║██████╔╝██║░░██║░░░██║░░░██║░░██║╚██████╔╝
╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝░╚═════╝░

##########################################################################################
#                                                                                        #
#                🚀 THIS SCRIPT IS CREATED BY **HASHTAG**! 🚀                           #
#                                                                                        #
#       🌐 Join our revolution in decentralized networks and crypto innovation!          #
#                                                                                        #
# 📢 Stay updated:                                                                       #
#     • Dm me on Telegram: https://t.me/Jayanth24                                        #
##########################################################################################

EOF

# Add some space after the banner
printf "\n\n"

# Green color for advertisement
GREEN="\033[0;32m"
RESET="\033[0m"

# Backup file path
backup_file="$HOME/nodes_backup.json"

# Function to display the menu
show_menu() {
    echo ""
    echo "🌌 Welcome to the Gaia Node Manager! - Made by HASHTAG"
    echo "🌌 For Doubts, Dm me on Telegram: https://t.me/Jayanth24 "
    echo ""
    echo "📝 Select an option:"
    echo "1). Install Packages"
    echo "2). Install Nodes (Max-5)"
    echo "3). Start Nodes"
    echo "4). Stop Nodes"
    echo "5). Get NodeId and DeviceId"
    echo "6). Create Nodes Data Backup File"
    echo "7). Recover Nodes Data From Backup File"
    echo "8). Delete All Nodes"
    echo "9). Exit"
}

# Function to install required packages
install_packages() {
    echo "📦 Installing required packages..."

    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root. Try: sudo $0"
        exit 1
    fi

    # Fix Google Chrome GPG key issue
    if ! test -f /etc/apt/trusted.gpg.d/google-chrome.asc; then
        echo "Adding Google Chrome GPG key..."
        wget -qO - https://dl.google.com/linux/linux_signing_key.pub | sudo tee /etc/apt/trusted.gpg.d/google-chrome.asc
    else
        echo "Google Chrome GPG key already exists, skipping."
    fi

    # Update package lists
    echo "Updating package list..."
    apt update -q || { echo "❌ Failed to update package list"; exit 1; }

    # Show upgradable packages
    echo "Checking for upgradable packages..."
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." || true)

    if [ -z "$UPGRADABLE" ]; then
        echo "All packages are up to date. Skipping upgrade."
    else
        echo "Upgradable packages found:"
        echo "$UPGRADABLE"
        echo "Upgrading packages..."
        apt upgrade -y || { echo "❌ Failed to upgrade packages"; exit 1; }
    fi

    # List of required packages
    REQUIRED_PACKAGES=(
        nvtop
        sudo
        curl
        htop
        systemd
        fonts-noto-color-emoji
        git
        nano
        jq
        screen
        net-tools
        lsof
    )

    # Install required packages
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -qw "$pkg"; then
            echo "❌ $pkg is not installed. Installing $pkg..."
            apt install -y "$pkg" || { echo "❌ Failed to install $pkg"; exit 1; }
        else
            echo "✅ $pkg is already installed, skipping."
        fi
    done

    echo "✅ All required packages have been installed or updated."
}

# Function to create a single node
create_node() {
    local node_number=$1
    local config_link=$2
    local folder_name="gaia-node-$node_number"
    local port_number=$((8100 + node_number))

    # Check if the folder already exists
    if [ -d "$HOME/$folder_name" ]; then
        echo "⚠️ Folder $folder_name already exists. Skipping folder creation."
        
        echo "🔧 Installing or reconfiguring node in $folder_name..."
        curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$HOME/$folder_name" || { echo "❌ Failed to install node"; exit 1; }
        source /root/.bashrc
    else
        # If the folder doesn't exist, create it and install the node
        echo "🚀 Creating node $node_number..."
        mkdir -p "$HOME/$folder_name"
        echo "📂 Folder created: $folder_name"

        curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$HOME/$folder_name" || { echo "❌ Failed to install node"; exit 1; }
        source /root/.bashrc
    fi

    # Initialize the node with the provided config link
    echo "⚙️ Initializing node with config: $config_link"
    gaianet init --base "$HOME/$folder_name" --config "$config_link" || { echo "❌ Failed to initialize node"; exit 1; }

    echo "🔧 Changing port to $port_number..."
    gaianet config --base "$HOME/$folder_name" --port "$port_number" || { echo "❌ Failed to change port"; exit 1; }

    echo "⚙️ Re-initializing node..."
    gaianet init --base "$HOME/$folder_name" || { echo "❌ Failed to re-initialize node"; exit 1; }

    echo "✅ Node $node_number setup completed successfully with config: $config_link"
}

# Function to start nodes
start_nodes() {
    echo "🚀 Starting nodes..."
    for i in {101..105}; do
        if [ -d "$HOME/gaia-node-$i" ]; then
            gaianet start --base "$HOME/gaia-node-$i" || { echo "❌ Failed to start gaia-node-$i"; continue; }
            echo "✅ Started gaia-node-$i"
        else
            echo "⚠️ Node gaia-node-$i not found. Skipping..."
        fi
        echo "════════════════════════════════════════════════════════════════════════════════"
    done
}

# Function to stop nodes
stop_nodes() {
    echo "🛑 Stopping nodes..."
    for i in {101..105}; do
        if [ -d "$HOME/gaia-node-$i" ]; then
            gaianet stop --base "$HOME/gaia-node-$i" || { echo "❌ Failed to stop gaia-node-$i"; continue; }
            echo "✅ Stopped gaia-node-$i"
        else
            echo "⚠️ Node gaia-node-$i not found. Skipping..."
        fi
        echo "════════════════════════════════════════════════════════════════════════════════"
    done
}

# Function to display NodeId and DeviceId
get_node_info() {
    echo "📄 Displaying NodeId and DeviceId..."
    for i in {101..105}; do
        node_path="$HOME/gaia-node-$i"
        
        if [ -d "$node_path" ]; then
            echo "🔍 Found: gaia-node-$i"
            gaianet info --base "$node_path" || { echo "❌ Failed to get info for gaia-node-$i"; continue; }
        else
            echo "⚠️  Not found: gaia-node-$i"
        fi
        
        echo "════════════════════════════════════════════════════════════════════════════════"
    done
}

# Function to create backup of nodes
backup_nodes() {
    if ! command -v jq &> /dev/null; then
        echo "❌ 'jq' is not installed. Please install it first."
        exit 1
    fi

    echo "📦 Creating backup of NodeId and DeviceId..."
    backup_data="{}"

    for i in {101..105}; do
        folder_name="gaia-node-$i"
        node_id_file="$HOME/$folder_name/nodeid.json"
        device_id_file="$HOME/$folder_name/deviceid.txt"

        if [[ -f "$node_id_file" && -f "$device_id_file" ]]; then
            node_id=$(cat "$node_id_file")
            device_id=$(cat "$device_id_file")

            backup_data=$(echo "$backup_data" | jq ". + {\"$folder_name\": { \"nodeid\": $node_id, \"deviceid\": \"$device_id\" }}")

            echo "✅ Backup for $folder_name completed!"
        else
            echo "❌ Skipping $folder_name (missing files)"
        fi
    done

    echo "$backup_data" > "$backup_file"
    echo "🚀 Backup saved to $backup_file"
}

# Function to recover nodes
recover_nodes() {
    if ! command -v jq &> /dev/null; then
        echo "❌ 'jq' is not installed. Please install it first."
        exit 1
    fi

    echo "🔄 Recovering nodes from backup..."

    if [[ ! -f "$backup_file" ]]; then
        echo "❌ No backup file found at $backup_file"
        return
    fi

    if ! jq empty "$backup_file" &> /dev/null; then
        echo "❌ Backup file is corrupted or invalid."
        return
    fi

    cat "$backup_file" | jq -c 'to_entries[]' | while IFS= read -r entry; do
        folder_name=$(echo "$entry" | jq -r '.key')
        node_id=$(echo "$entry" | jq -c '.value.nodeid')
        device_id=$(echo "$entry" | jq -r '.value.deviceid')

        if [ -d "$HOME/$folder_name" ]; then
            echo "⚠️ Folder $folder_name already exists. Skipping."
        else
            echo "📂 Creating folder: $folder_name"
            mkdir -p "$HOME/$folder_name"

            echo "$node_id" > "$HOME/$folder_name/nodeid.json"
            echo "$device_id" > "$HOME/$folder_name/deviceid.txt"

            echo "✅ Node $folder_name recovered successfully!"
        fi
    done
}

# Function to delete nodes
delete_nodes() {
    echo "🗑️ Are you sure you want to delete all nodes? This action cannot be undone. (yes/no)"
    read -r confirmation
    if [[ "$confirmation" != "yes" ]]; then
        echo "❌ Node deletion canceled."
        return
    fi

    echo "🗑️ Deleting all nodes..."
    for i in {101..105}; do
        folder_name="gaia-node-$i"
        
        if [ -d "$HOME/$folder_name" ]; then
            gaianet stop --base "$HOME/$folder_name" || { echo "❌ Failed to stop $folder_name"; continue; }
            rm -rf "$HOME/$folder_name"
            echo "🗑️ Deleted $folder_name"
        else
            echo "⚠️ Node $folder_name not found. Skipping..."
        fi
        
        echo "════════════════════════════════════════════════════════════════════════════════"
    done
}

# Main script loop
while true; do
    show_menu
    read -rp "Enter your choice: " choice
    case $choice in
        1) install_packages ;;
        2) 
            echo "📝 Enter config link for all nodes:"
            while true; do
                read -r config_link
                if [[ $config_link =~ ^https?:// ]]; then
                    break
                else
                    echo "❌ Invalid config link. Please enter a valid URL starting with http:// or https://"
                fi
            done

            echo "Enter number of nodes to create (1-5):"
            read -r count
            if ! [[ "$count" =~ ^[1-5]$ ]]; then
                echo "❌ Invalid input! Please enter a number between 1 and 5."
            else
                for ((i = 1; i <= count; i++)); do
                    create_node "$((100 + i))" "$config_link"
                done
            fi
            ;;
        3) start_nodes ;;
        4) stop_nodes ;;
        5) get_node_info ;;
        6) backup_nodes ;;
        7) recover_nodes ;;
        8) delete_nodes ;;
        9) echo "⏹️ Exiting..."; exit 0 ;;
        *) echo "❌ Invalid choice. Please enter a valid option." ;;
    esac
done
