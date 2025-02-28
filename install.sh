#!/bin/bash

set -e

# version of CLI tool
# Note that the version should kept same as the version of installer
version="0.4.20"

# version of the GaiaNet node
# Note that the version should kept same as the version of installer
installer_version="0.4.20"

# path to the default gaianet base directory. It could be changed by the --base option
gaianet_base_dir="$HOME/gaianet"

# We will make sure that the path is setup in case the user runs gaianet immediately after init
source $HOME/.wasmedge/env

# print in red color
RED=$'\e[0;31m'
# print in green color
GREEN=$'\e[0;32m'
# print in yellow color
YELLOW=$'\e[0;33m'
# No Color
NC=$'\e[0m'

# Mac OS requires this hack in order to run qdrant reliablly
if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    ulimit -n 10000
fi

info() {
    printf "${GREEN}$1${NC}\n\n"
}

error() {
    printf "${RED}$1${NC}\n\n"
}

warning() {
    printf "${YELLOW}$1${NC}\n\n"
}

# download target file to destination. If failed, then exit
check_curl() {
    curl --retry 3 --progress-bar -L "$1" -o "$2"

    if [ $? -ne 0 ]; then
        error "    * Failed to download $1"
        exit 1
    fi
}

check_curl_silent() {
    curl --retry 3 -s --progress-bar -L "$1" -o "$2"

    if [ $? -ne 0 ]; then
        error "    * Failed to download $1"
        exit 1
    fi
}

check_base_dir() {
    # Check if $gaianet_base_dir directory exists
    if [ ! -d $gaianet_base_dir ]; then
        printf "\n[Error] Not found $gaianet_base_dir.\n\nPlease run 'bash install.sh' command first, then try again.\n\n"
        exit 1
    fi
}

sed_in_place() {
    if [ "$(uname)" == "Darwin" ]; then
        sed -i '' "$@"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        sed -i "$@"
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
        error "    * For Windows users, please run this script in WSL."
        exit 1
    else
        error "    * Only support Linux, MacOS and Windows."
        exit 1
    fi
}

# check the validity of the config.json file
check_config_options() {

    # check if config.json exists or not
    if [ ! -f "$gaianet_base_dir/config.json" ]; then
        error "Not found config.json file in $gaianet_base_dir"
        exit 1
    fi

    # check if the `address` field exists or not
    if ! grep -q '"address":' $gaianet_base_dir/config.json; then
        error "Not found the 'address' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `chat` field exists or not
    if ! grep -q '"chat":' $gaianet_base_dir/config.json; then
        error "Not found the 'chat' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `prompt_template` field exists or not
    if ! grep -q '"prompt_template":' $gaianet_base_dir/config.json; then
        error "Not found the 'prompt_template' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `chat_ctx_size` field exists or not
    if ! grep -q '"chat_ctx_size":' $gaianet_base_dir/config.json; then
        error "Not found the 'chat_ctx_size' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `system_prompt` field exists or not
    if ! grep -q '"system_prompt":' $gaianet_base_dir/config.json; then
        error "Not found the 'system_prompt' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `embedding` field exists or not
    if ! grep -q '"embedding":' $gaianet_base_dir/config.json; then
        error "Not found the 'embedding' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `embedding_ctx_size` field exists or not
    if ! grep -q '"embedding_ctx_size":' $gaianet_base_dir/config.json; then
        error "Not found the 'embedding_ctx_size' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `snapshot` field exists or not
    if ! grep -q '"snapshot":' $gaianet_base_dir/config.json; then
        error "Not found the 'snapshot' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `embedding_collection_name` field exists or not
    if ! grep -q '"embedding_collection_name":' $gaianet_base_dir/config.json; then
        error "Not found the 'embedding_collection_name' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `qdrant_limit` field exists or not
    if ! grep -q '"qdrant_limit":' $gaianet_base_dir/config.json; then
        error "Not found the 'qdrant_limit' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `qdrant_score_threshold` field exists or not
    if ! grep -q '"qdrant_score_threshold":' $gaianet_base_dir/config.json; then
        error "Not found the 'qdrant_score_threshold' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `rag_prompt` field exists or not
    if ! grep -q '"rag_prompt":' $gaianet_base_dir/config.json; then
        error "Not found the 'rag_prompt' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `rag_policy` field exists or not
    if ! grep -q '"rag_policy":' $gaianet_base_dir/config.json; then
        error "Not found the 'rag_policy' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `domain` field exists or not
    if ! grep -q '"domain":' $gaianet_base_dir/config.json; then
        error "Not found the 'domain' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

    # check if the `llamaedge_port` field exists or not
    if ! grep -q '"llamaedge_port":' $gaianet_base_dir/config.json; then
        error "Not found the 'llamaedge_port' field in $gaianet_base_dir/config.json\n"
        exit 1
    fi

}

# create or recover a qdrant collection
create_collection() {
    printf "[+] Creating 'default' collection in the Qdrant instance ...\n"

    qdrant_pid=0
    qdrant_already_running=false
    if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        if lsof -Pi :6333 -sTCP:LISTEN -t >/dev/null ; then
            warning "    * A Qdrant instance is already running"
            qdrant_already_running=true
        fi
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
        printf "For Windows users, please run this script in WSL.\n"
        exit 1
    else
        printf "Only support Linux, MacOS and Windows.\n"
        exit 1
    fi

    if [ "$qdrant_already_running" = false ]; then
        printf "    * Start a Qdrant instance ...\n\n"
        # start qdrant
        cd $gaianet_base_dir/qdrant

        # check if `log` directory exists or not
        if [ ! -d "$gaianet_base_dir/log" ]; then
            mkdir -p -m777 $gaianet_base_dir/log
        fi
        log_dir=$gaianet_base_dir/log

        nohup $gaianet_base_dir/bin/qdrant > $log_dir/init-qdrant.log 2>&1 &
        sleep 10
        qdrant_pid=$!
    fi

    cd $gaianet_base_dir
    url_snapshot=$(awk -F'"' '/"snapshot":/ {print $4}' config.json)
    url_document=$(awk -F'"' '/"document":/ {print $4}' config.json)
    embedding_collection_name=$(awk -F'"' '/"embedding_collection_name":/ {print $4}' config.json)
    if [[ -z "$embedding_collection_name" ]]; then
        embedding_collection_name="default"
    fi

    printf "    * Remove the existed 'default' Qdrant collection ...\n\n"
    cd $gaianet_base_dir
    # remove the collection if it exists
    del_response=$(curl -s -X DELETE http://localhost:6333/collections/$embedding_collection_name \
        -H "Content-Type: application/json")

    curl_exit_status=$?

    if [ $curl_exit_status -ne 0 ]; then
        error "      Failed to remove the $embedding_collection_name collection. Exit."

        if [ "$qdrant_already_running" = false ]; then
            kill $qdrant_pid
        fi

        exit 1
    fi

    status=$(echo "$del_response" | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    if [ "$status" != "ok" ]; then
        error "      Failed to remove the $embedding_collection_name collection. $del_response"

        if [ "$qdrant_already_running" = false ]; then
            kill $qdrant_pid
        fi

        exit 1
    fi

    # 10.1 recover from the given qdrant collection snapshot
    if [ -n "$url_snapshot" ]; then
        # Regular expression for URL validation
        regex='(https?|ftp)://[-[:alnum:]\+&@#/%?=~_|!:,.;]+'

        # Check if $url_snapshot is a valid URL
        if [[ $url_snapshot =~ $regex ]]; then
            printf "    * Download Qdrant collection snapshot ...\n"
            if [[ $url_snapshot == *.tar.gz ]]; then
                filename=$(basename $url_snapshot)
                check_curl $url_snapshot $gaianet_base_dir/$filename
                tar -xzOf $gaianet_base_dir/$filename > $gaianet_base_dir/default.snapshot
                rm $gaianet_base_dir/$filename
            else
                check_curl $url_snapshot $gaianet_base_dir/default.snapshot
            fi
            info "      The snapshot is downloaded in $gaianet_base_dir"

        # Check if $url_snapshot is a local file
        elif [ -f "$gaianet_base_dir/$url_snapshot" ]; then
            info "      * Use local snapshot: $url_snapshot"
            if [[ $url_snapshot == *.tar.gz ]]; then
                tar -xzOf $gaianet_base_dir/$url_snapshot > $gaianet_base_dir/default.snapshot
            else
                # make a copy of the original snapshot file
                cp $gaianet_base_dir/$url_snapshot $gaianet_base_dir/default.snapshot
            fi

        else
            echo "$url_snapshot is neither a valid URL nor a local file."
        fi

        printf "    * Import the Qdrant collection snapshot ...\n"
        printf "      The process may take a few minutes. Please wait ...\n"
        # Import the default.snapshot file
        cd $gaianet_base_dir
        response=$(curl -s -X POST http://localhost:6333/collections/$embedding_collection_name/snapshots/upload?priority=snapshot \
            -H 'Content-Type:multipart/form-data' \
            -F 'snapshot=@default.snapshot')
        sleep 5

        if echo "$response" | grep -q '"status":"ok"'; then
            rm $gaianet_base_dir/default.snapshot
            info "      Recovery is done!"
        else
            error "    * [Error] Failed to recover from the collection snapshot. $response"

            if [ "$qdrant_already_running" = false ]; then
                info "    * Stop the Qdrant instance ..."
                kill -9 $qdrant_pid
            fi

            exit 1
        fi

    # 10.2 generate a Qdrant collection from the given document
    elif [ -n "$url_document" ]; then
        printf "    * Create 'default' Qdrant collection from the given document ...\n\n"

        # Start LlamaEdge API Server
        printf "    * Start LlamaEdge-RAG API Server ...\n\n"

        # parse cli options for chat model
        cd $gaianet_base_dir

        url_chat_model=$(awk -F'"' '/"chat":/ {print $4}' config.json)
        # gguf filename
        chat_model_name=$(basename $url_chat_model)
        # Directly attempt to extract "chat_name" and fallback to extracting from "chat" if empty
        chat_name=$(grep '"chat_name":' config.json | sed -E 's/.*"chat_name": *"([^"]*)".*/\1/')
        if [ -z "$chat_name" ]; then
            chat_model_stem=$(basename "${url_chat_model%.*}")
        else
            chat_model_stem=$chat_name
        fi

        # parse context size for chat model
        chat_ctx_size=$(awk -F'"' '/"chat_ctx_size":/ {print $4}' config.json)
        # parse prompt type for chat model
        prompt_type=$(awk -F'"' '/"prompt_template":/ {print $4}' config.json)
        # parse reverse prompt for chat model
        reverse_prompt=$(awk -F'"' '/"reverse_prompt":/ {print $4}' config.json)

        url_embedding_model=$(awk -F'"' '/"embedding":/ {print $4}' config.json)
        # gguf filename
        embedding_model_name=$(basename $url_embedding_model)
        # Directly attempt to extract "embedding_name" and fallback to extracting from "embedding" if empty
        embedding_name=$(grep '"embedding_name":' config.json | sed -E 's/.*"embedding_name": *"([^"]*)".*/\1/')
        if [ -z "$embedding_name" ]; then
            embedding_model_stem=$(basename "${url_embedding_model%.*}")
        else
            embedding_model_stem=$embedding_name
        fi

        # parse context size for embedding model
        embedding_ctx_size=$(awk -F'"' '/"embedding_ctx_size":/ {print $4}' config.json)
        # parse cli options for embedding vector collection name
        embedding_collection_name=$(awk -F'"' '/"embedding_collection_name":/ {print $4}' config.json)
        if [[ -z "$embedding_collection_name" ]]; then
            embedding_collection_name="default"
        fi
        # parse port for LlamaEdge API Server
        llamaedge_port=$(awk -F'"' '/"llamaedge_port":/ {print $4}' config.json)

        if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            if lsof -Pi :$llamaedge_port -sTCP:LISTEN -t >/dev/null ; then
                error "      It appears that the GaiaNet node is running. Please stop it first."

                if [ "$qdrant_already_running" = false ]; then
                    kill $qdrant_pid
                fi

                exit 1
            fi
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
            error "      For Windows users, please run this script in WSL."

            if [ "$qdrant_already_running" = false ]; then
                kill $qdrant_pid
            fi

            exit 1
        else
            error "      Only support Linux, MacOS and Windows."

            if [ "$qdrant_already_running" = false ]; then
                kill $qdrant_pid
            fi

            exit 1
        fi

        # command to start LlamaEdge API Server
        cd $gaianet_base_dir
        cmd="wasmedge --dir .:. \
        --env NODE_VERSION=$installer_version \
        --nn-preload default:GGML:AUTO:$chat_model_name \
        --nn-preload embedding:GGML:AUTO:$embedding_model_name \
        rag-api-server.wasm \
        --prompt-template $prompt_type,embedding \
        --model-name $chat_model_stem,$embedding_model_stem \
        --ctx-size $chat_ctx_size,$embedding_ctx_size \
        --qdrant-collection-name $embedding_collection_name \
        --include-usage \
        --web-ui ./dashboard \
        --socket-addr 0.0.0.0:$llamaedge_port"

        nohup $cmd > $log_dir/init-qdrant-gen-collection.log 2>&1 &
        sleep 5
        llamaedge_pid=$!
        echo $llamaedge_pid > $gaianet_base_dir/llamaedge.pid

        printf "    * Convert document to embeddings ...\n"
        printf "      The process may take a few minutes. Please wait ...\n\n"
        cd $gaianet_base_dir
        doc_filename=$(basename $url_document)
        check_curl_silent $url_document $gaianet_base_dir/$doc_filename

        if [[ $doc_filename != *.txt ]] && [[ $doc_filename != *.md ]]; then
            error "The document to upload should be a file with 'txt' or 'md' extension."

            # stop the api-server
            if [ -f "$gaianet_base_dir/llamaedge.pid" ]; then
                kill $(cat $gaianet_base_dir/llamaedge.pid)
                rm $gaianet_base_dir/llamaedge.pid
            fi

            if [ "$qdrant_already_running" = false ]; then
                kill $qdrant_pid
            fi

            exit 1
        fi

        # compute embeddings
        embedding_response=$(curl -s -X POST http://127.0.0.1:$llamaedge_port/v1/create/rag -F "file=@$doc_filename")

        # remove the downloaded document
        rm -f $gaianet_base_dir/$doc_filename

        # stop the api-server
        if [ -f "$gaianet_base_dir/llamaedge.pid" ]; then
            # stop API server
            kill $(cat $gaianet_base_dir/llamaedge.pid)
            rm $gaianet_base_dir/llamaedge.pid
        fi

        if [ -z "$embedding_response" ]; then
            error "      Failed to compute embeddings. Exit."

            if [ "$qdrant_already_running" = false ]; then
                kill $qdrant_pid
            fi

            exit 1
        else
            info "    * Embeddings are computed successfully"
        fi

    else
        error "Please set 'snapshot' or 'document' field in config.json. Exit."

        if [ "$qdrant_already_running" = false ]; then
            kill $qdrant_pid
        fi

        exit 1
    fi

    if [ "$qdrant_already_running" = false ]; then
        # stop qdrant
        kill $qdrant_pid
    fi

    # sleep for a while to make sure the qdrant instance is stopped
    sleep 10
}

# * init subcommand

init() {

    # check if config.json exists or not
    printf "[+] Checking the config.json file ...\n"
    check_config_options
    printf "\n"

    # download GGUF chat model file to $gaianet_base_dir
    url_chat_model=$(awk -F'"' '/"chat":/ {print $4}' $gaianet_base_dir/config.json)
    chat_model=$(basename $url_chat_model)
    if [[ $url_chat_model =~ ^http[s]?://.* ]]; then
        printf "[+] Downloading $chat_model ...\n"
        if [ -f "$gaianet_base_dir/$chat_model" ]; then
            warning "    * Using the cached $chat_model in $gaianet_base_dir"
        else
            check_curl $url_chat_model $gaianet_base_dir/$chat_model
            info "    * $chat_model is downloaded in $gaianet_base_dir"
        fi
    elif [[ $url_chat_model =~ .*\.gguf$ ]]; then
        printf "[+] Using local $chat_model ...\n"
        if [ -f "$gaianet_base_dir/$chat_model" ]; then
            warning "    * Found $chat_model in $gaianet_base_dir"
        else
            error "    * Not found $chat_model in $gaianet_base_dir. Exit ..."
            exit 1
        fi
    else
        error "Error: The 'chat' field in $gaianet_base_dir/config.json should be a url or a gguf model file. Exit ..."
        exit 1
    fi

    # download GGUF embedding model file to $gaianet_base_dir
    url_embedding_model=$(awk -F'"' '/"embedding":/ {print $4}' $gaianet_base_dir/config.json)
    embedding_model=$(basename $url_embedding_model)
    if [[ $url_embedding_model =~ ^http[s]?://.* ]]; then
        printf "[+] Downloading $embedding_model ...\n"
        if [ -f "$gaianet_base_dir/$embedding_model" ]; then
            warning "    * Using the cached $embedding_model in $gaianet_base_dir"
        else
            check_curl $url_embedding_model $gaianet_base_dir/$embedding_model
            info "    * $embedding_model is downloaded in $gaianet_base_dir"
        fi
    elif [[ $url_embedding_model =~ .*\.gguf$ ]]; then
        printf "[+] Using local $embedding_model ...\n"
        if [ -f "$gaianet_base_dir/$embedding_model" ]; then
            warning "    * Found $embedding_model in $gaianet_base_dir"
        else
            error "    * Not found $embedding_model in $gaianet_base_dir. Exit ..."
            exit 1
        fi
    else
        error "Error: The 'embedding' field in $gaianet_base_dir/config.json should be a url or a gguf model file. Exit ..."
        exit 1
    fi

    snapshot=$(awk -F'"' '/"snapshot":/ {print $4}' $gaianet_base_dir/config.json)
    if [ -n "$snapshot" ]; then
        # create or recover a qdrant collection
        create_collection
    fi

    # Copy config to dashboard
    if [ ! -f "$gaianet_base_dir/registry.wasm" ] ; then
        printf "[+] Downloading the registry.wasm ...\n"

        check_curl_silent https://github.com/GaiaNet-AI/gaianet-node/raw/main/utils/registry/registry.wasm $gaianet_base_dir/registry.wasm

        printf "\n"
    fi
    printf "[+] Preparing the dashboard ...\n"
    cd $gaianet_base_dir
    wasmedge --dir .:. registry.wasm
    printf "\n"

    printf "[+] Preparing the GaiaNet domain ...\n"
    # Update frpc.toml
    address=$(awk -F'"' '/"address":/ {print $4}' $gaianet_base_dir/config.json)
    domain=$(awk -F'"' '/"domain":/ {print $4}' $gaianet_base_dir/config.json)
    llamaedge_port=$(awk -F'"' '/"llamaedge_port":/ {print $4}' $gaianet_base_dir/config.json)

    sed_in_place "s/subdomain = \".*\"/subdomain = \"$address\"/g" $gaianet_base_dir/gaia-frp/frpc.toml
    sed_in_place "s/name = \".*\"/name = \"$address.$domain\"/g" $gaianet_base_dir/gaia-frp/frpc.toml
    sed_in_place "s/localPort = .*/localPort = $llamaedge_port/g" $gaianet_base_dir/gaia-frp/frpc.toml
    sed_in_place "s/serverAddr = \".*\"/serverAddr = \"$domain\"/g" $gaianet_base_dir/gaia-frp/frpc.toml

    # Remove all files in the directory except for frpc and frpc.toml
    find $gaianet_base_dir/gaia-frp -type f -not -name 'frpc' -not -name 'frpc.toml' -exec rm -f {} \;

    printf "\n"

    printf "[+] COMPLETED! GaiaNet node is initialized successfully.\n\n"

    info ">>> To start the GaiaNet node, run the command: gaianet start <<<"
}

# * config subcommand
update_config() {
    key=$1
    new_value=$2
    file=$gaianet_base_dir/config.json

    # update in place
    if [ -z "$new_value" ]; then
        sed_in_place "s/\(\"$key\": \s*\).*\,/\1\"$new_value\",/" $file
    else
        sed_in_place "/\"$key\":/ s#: \".*\"#: \"$new_value\"#" $file
    fi
}

# * start subcommand

# start rag-api-server and a qdrant instance
start() {
    local_only=$1
    force_rag=$2
    log_dir=$gaianet_base_dir/log
    if ! [ -d "$log_dir" ]; then
        mkdir -p -m777 $log_dir
    fi

    local_log_storage=1
    if command -v vector > /dev/null 2>&1 && [ -f $gaianet_base_dir/vector.toml ]; then
        local_log_storage=0
    fi

    # check if config.json exists or not
    printf "[+] Checking the config.json file ...\n"
    check_config_options
    printf "\n"

    # sync the config.json to dashboard/config_pub.json
    cd $gaianet_base_dir
    wasmedge --dir .:. registry.wasm

    # check if supervise is installed or not
    use_supervise=true
    if ! command -v supervise &> /dev/null; then
        use_supervise=false
    fi

    snapshot=$(awk -F'"' '/"snapshot":/ {print $4}' $gaianet_base_dir/config.json)
    if [ -n "$snapshot" ] || [ "$force_rag" = true ]; then
        # 1. start a Qdrant instance
        printf "[+] Starting Qdrant instance ...\n"

        qdrant_already_running=false
        if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            if lsof -Pi :6333 -sTCP:LISTEN -t >/dev/null ; then
                qdrant_already_running=true
            fi
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
            printf "For Windows users, please run this script in WSL.\n"
            exit 1
        else
            printf "Only support Linux, MacOS and Windows.\n"
            exit 1
        fi

        if [ "$qdrant_already_running" = false ]; then
            qdrant_executable="$gaianet_base_dir/bin/qdrant"
            if [ -f "$qdrant_executable" ]; then
                cd $gaianet_base_dir/qdrant
                nohup $qdrant_executable > $log_dir/start-qdrant.log 2>&1 &
                sleep 2
                qdrant_pid=$!
                echo $qdrant_pid > $gaianet_base_dir/qdrant.pid
                info "\n    Qdrant instance started with pid: $qdrant_pid"
            else
                error "    Qdrant binary not found at $qdrant_executable\n\n"
                exit 1
            fi
        fi

        # 2. start rag-api-server
        printf "[+] Starting LlamaEdge API Server ...\n\n"

        # parse cli options for chat model
        cd $gaianet_base_dir

        url_chat_model=$(awk -F'"' '/"chat":/ {print $4}' config.json)
        # gguf filename
        chat_model_name=$(basename $url_chat_model)
        # Directly attempt to extract "chat_name" and fallback to extracting from "chat" if empty
        chat_name=$(grep '"chat_name":' config.json | sed -E 's/.*"chat_name": *"([^"]*)".*/\1/')
        if [ -z "$chat_name" ]; then
            chat_model_stem=$(basename "${url_chat_model%.*}")
        else
            chat_model_stem=$chat_name
        fi

        # parse context size for chat model
        chat_ctx_size=$(awk -F'"' '/"chat_ctx_size":/ {print $4}' config.json)
        # parse batch size for chat model
        chat_batch_size=$(awk -F'"' '/"chat_batch_size":/ {print $4}' config.json)
        # parse ubatch size for chat model
        if grep -q '"chat_ubatch_size":' config.json; then
            chat_ubatch_size=$(awk -F'"' '/"chat_ubatch_size":/ {print $4}' config.json)
        else
            chat_ubatch_size=$chat_batch_size
        fi
        # parse prompt type for chat model
        prompt_type=$(awk -F'"' '/"prompt_template":/ {print $4}' config.json)
        # parse system prompt for chat model
        rag_prompt=$(awk -F'"' '/"rag_prompt":/ {print $4}' config.json)
        # parse reverse prompt for chat model
        reverse_prompt=$(awk -F'"' '/"reverse_prompt":/ {print $4}' config.json)
        # parse rag policy
        if grep -q '"rag_policy":' config.json; then
            rag_policy=$(awk -F'"' '/"rag_policy":/ {print $4}' config.json)
        else
            rag_policy="system-message"
        fi

        url_embedding_model=$(awk -F'"' '/"embedding":/ {print $4}' config.json)
        # gguf filename
        embedding_model_name=$(basename $url_embedding_model)
        # Directly attempt to extract "embedding_name" and fallback to extracting from "embedding" if empty
        embedding_name=$(grep '"embedding_name":' config.json | sed -E 's/.*"embedding_name": *"([^"]*)".*/\1/')
        if [ -z "$embedding_name" ]; then
            embedding_model_stem=$(basename "${url_embedding_model%.*}")
        else
            embedding_model_stem=$embedding_name
        fi

        # parse cli options for embedding vector collection name
        embedding_collection_name=$(awk -F'"' '/"embedding_collection_name":/ {print $4}' config.json)
        if [[ -z "$embedding_collection_name" ]]; then
            embedding_collection_name="default"
        fi
        # parse context size for embedding model
        embedding_ctx_size=$(awk -F'"' '/"embedding_ctx_size":/ {print $4}' config.json)
        # parse batch size for embedding model
        embedding_batch_size=$(awk -F'"' '/"embedding_batch_size":/ {print $4}' config.json)
        # parse ubatch size for embedding model
        if grep -q '"embedding_ubatch_size":' config.json; then
            embedding_ubatch_size=$(awk -F'"' '/"embedding_ubatch_size":/ {print $4}' config.json)
        else
            embedding_ubatch_size=$embedding_batch_size
        fi
        # parse port for LlamaEdge API Server
        llamaedge_port=$(awk -F'"' '/"llamaedge_port":/ {print $4}' config.json)
        # parse qdrant limit
        qdrant_limit=$(awk -F'"' '/"qdrant_limit":/ {print $4}' config.json)
        # parse qdrant score threshold
        qdrant_score_threshold=$(awk -F'"' '/"qdrant_score_threshold":/ {print $4}' config.json)
        # parse context window
        # check if context window is present in config.json
        if grep -q '"context_window":' config.json; then
            context_window=$(awk -F'"' '/"context_window":/ {print $4}' config.json)
        else
            context_window=1
        fi

        if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            if lsof -Pi :$llamaedge_port -sTCP:LISTEN -t >/dev/null ; then
                printf "    Port $llamaedge_port is in use. Exit ...\n\n"

                # stop the qdrant instance
                if [ "$qdrant_already_running" = false ]; then

                    # stop the Qdrant instance
                    qdrant_pid=$gaianet_base_dir/qdrant.pid
                    if [ -f $qdrant_pid ]; then
                        printf "    Stopping Qdrant instance ...\n"
                        kill -9 $(cat $qdrant_pid)
                        rm $qdrant_pid
                    fi

                fi

                exit 1
            fi
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
            printf "For Windows users, please run this script in WSL.\n"
            exit 1
        else
            printf "Only support Linux, MacOS and Windows.\n"
            exit 1
        fi

        cd $gaianet_base_dir
        llamaedge_wasm="$gaianet_base_dir/rag-api-server.wasm"
        if [ ! -f "$llamaedge_wasm" ]; then
            error "Not found rag-api-server.wasm at $$gaianet_base_dir"
            exit 1
        fi

        # command to start LlamaEdge API Server
        cd $gaianet_base_dir
        cmd=(wasmedge --dir .:./dashboard \
        --env NODE_VERSION=$installer_version \
        --nn-preload default:GGML:AUTO:$chat_model_name \
        --nn-preload embedding:GGML:AUTO:$embedding_model_name \
        rag-api-server.wasm \
        --model-name $chat_model_stem,$embedding_model_stem \
        --ctx-size $chat_ctx_size,$embedding_ctx_size \
        --batch-size $chat_batch_size,$embedding_batch_size \
        --ubatch-size $chat_ubatch_size,$embedding_ubatch_size \
        --prompt-template $prompt_type,embedding \
        --rag-policy $rag_policy \
        --qdrant-collection-name $embedding_collection_name \
        --qdrant-limit $qdrant_limit \
        --qdrant-score-threshold $qdrant_score_threshold \
        --context-window $context_window \
        --include-usage \
        --web-ui ./ \
        --socket-addr 0.0.0.0:$llamaedge_port)

        if $use_supervise; then
            cmd_string=""
            for i in "${cmd[@]}"; do
                if [[ $i == *" "* ]]; then
                    cmd_string+=\""$i"\"
                else
                    cmd_string+="$i"
                fi
                cmd_string+=" "
            done
        fi

        # Add rag prompt if it exists
        if [ -n "$rag_prompt" ]; then
            cmd+=("--rag-prompt" "$rag_prompt")

            if $use_supervise; then
                cmd_string+="--rag-prompt \"$rag_prompt\" "
            fi
        fi

        # Add reverse prompt if it exists
        if [ -n "$reverse_prompt" ]; then
            cmd+=("--reverse-prompt" "$reverse_prompt")

            if $use_supervise; then
                cmd_string+="--reverse-prompt \"$reverse_prompt\" "
            fi
        fi

        printf "    Run the following command to start the LlamaEdge API Server:\n\n"
        for i in "${cmd[@]}"; do
            if [[ $i == *" "* ]]; then
                printf "\"%s\" " "$i"
            else
                printf "%s " "$i"
            fi
        done
        printf "\n\n"

        if $use_supervise; then
            # create `run` file for supervise
            echo '#!/bin/bash' > $gaianet_base_dir/run
            echo $cmd_string >> $gaianet_base_dir/run
            chmod u+x $gaianet_base_dir/run
        fi

        # start api-server
        retry_count=0
        start_retry_cout=0
        max_retries=3
        while true; do

            # start api-server
            if $use_supervise; then
                # start LlamaEdge API Server with supervise
                if [ "$local_log_storage" -eq 1 ]; then
                    nohup supervise $gaianet_base_dir > $log_dir/start-llamaedge.log 2>&1 &
                else
                    nohup supervise $gaianet_base_dir | vector --config $gaianet_base_dir/vector.toml > $log_dir/start-vector.log 2>&1 &
                fi
                sleep 2
                supervise_pid=$!
                echo $supervise_pid > $gaianet_base_dir/supervise.pid
                printf "\n    Daemotools-Supervise started with pid: $supervise_pid\n"

                # Get the status of the service
                status=$(svstat $gaianet_base_dir)
                # Extract the PID from the status
                llamaedge_pid=$(echo $status | awk '{print $4}' | tr -d ')')
                # The reason of incrementing the PID by 1 is that the PID returned by `svstat` is less 1 than the PID returned by `pgrep`
                llamaedge_pid=$((llamaedge_pid + 1))
                echo $llamaedge_pid > $gaianet_base_dir/llamaedge.pid
                info "\n    LlamaEdge-RAG API Server started with pid: $llamaedge_pid"

            else
                # start LlamaEdge API Server with nohup
                if [ "$local_log_storage" -eq 1 ]; then
                    nohup "${cmd[@]}" > $log_dir/start-llamaedge.log 2>&1 &
                else
                    nohup "${cmd[@]}" | vector --config $gaianet_base_dir/vector.toml > $log_dir/start-vector.log 2>&1 &
                fi
                sleep 2
                llamaedge_pid=$!
                echo $llamaedge_pid > $gaianet_base_dir/llamaedge.pid
                info "    LlamaEdge API Server started with pid: $llamaedge_pid"
            fi

            sleep 10
            info "    Verify the LlamaEdge-RAG API Server. Please wait seconds ..."
            if [[ "$prompt_type" == *"tool"* ]]; then
                status_code=$(curl -o /dev/null -s -w "%{http_code}\n" \
                    -X POST http://localhost:$llamaedge_port/v1/chat/completions \
                    -H 'accept:application/json' \
                    -H 'Content-Type: application/json' \
                    -d "{\"messages\":[{\"role\":\"user\", \"content\": \"What is your name?\"}], \"tools\":[{\"type\":\"function\",\"function\":{\"name\":\"get_name\",\"description\":\"Return your name\"}}], \"model\":\"$chat_model_stem\"}")
            else
                status_code=$(curl -o /dev/null -s -w "%{http_code}\n" \
                    -X POST http://localhost:$llamaedge_port/v1/chat/completions \
                    -H 'accept:application/json' \
                    -H 'Content-Type: application/json' \
                    -d "{\"messages\":[{\"role\":\"user\", \"content\": \"What is your name?\"}], \"model\":\"$chat_model_stem\"}")
            fi

            curl_exit_status=$?

            if [ $curl_exit_status -eq 0 ] && [ "$status_code" -eq 200 ]; then
                info "    * LlamaEdge-RAG API Server is ready."
                break
            else
                tail -2 $log_dir/start-llamaedge.log

                # stop the api-server
                pkill -9 wasmedge || true

                # stop supervise if it is running
                if svok $gaianet_base_dir > /dev/null 2>&1; then
                    svc -d $gaianet_base_dir
                    svc -k $gaianet_base_dir
                    svc -x $gaianet_base_dir
                    supervise_pid=$gaianet_base_dir/supervise.pid
                    if [ -f $supervise_pid ]; then
                        rm $supervise_pid
                    fi
                    rm $gaianet_base_dir/run
                    rm -rf $gaianet_base_dir/supervise
                fi

                # remove the pid file
                llamaedge_pid=$gaianet_base_dir/llamaedge.pid
                if [ -f $llamaedge_pid ]; then
                    rm $llamaedge_pid
                fi

                sleep 10  # wait for 10 seconds before retrying

                ((start_retry_cout++))
                if [ $start_retry_cout -ge $((max_retries + 1)) ]; then
                    error "    * Failed to start LlamaEdge API Server after $max_retries retries. Exiting ..."

                    # stop the Qdrant instance
                    pkill -9 qdrant || true
                    qdrant_pid=$gaianet_base_dir/qdrant.pid
                    if [ -f $qdrant_pid ]; then
                        rm $qdrant_pid
                    fi

                    # wait for 3 seconds before exiting
                    sleep 3

                    exit 1
                else
                    error "    * LlamaEdge API Server is not ready. Retrying ($start_retry_cout)..."
                fi
            fi

        done

    else

        # 2. start llama-api-server
        printf "[+] Starting LlamaEdge API Server ...\n\n"

        # parse cli options for chat model
        cd $gaianet_base_dir

        url_chat_model=$(awk -F'"' '/"chat":/ {print $4}' config.json)
        # gguf filename
        chat_model_name=$(basename $url_chat_model)
        # Directly attempt to extract "chat_name" and fallback to extracting from "chat" if empty
        chat_name=$(grep '"chat_name":' config.json | sed -E 's/.*"chat_name": *"([^"]*)".*/\1/')
        if [ -z "$chat_name" ]; then
            chat_model_stem=$(basename "${url_chat_model%.*}")
        else
            chat_model_stem=$chat_name
        fi

        # parse context size for chat model
        chat_ctx_size=$(awk -F'"' '/"chat_ctx_size":/ {print $4}' config.json)
        # parse batch size for chat model
        chat_batch_size=$(awk -F'"' '/"chat_batch_size":/ {print $4}' config.json)
        # parse ubatch size for chat model
        if grep -q '"chat_ubatch_size":' config.json; then
            chat_ubatch_size=$(awk -F'"' '/"chat_ubatch_size":/ {print $4}' config.json)
        else
            chat_ubatch_size=$chat_batch_size
        fi
        # parse prompt type for chat model
        prompt_type=$(awk -F'"' '/"prompt_template":/ {print $4}' config.json)
        # parse reverse prompt for chat model
        reverse_prompt=$(awk -F'"' '/"reverse_prompt":/ {print $4}' config.json)

        url_embedding_model=$(awk -F'"' '/"embedding":/ {print $4}' config.json)
        # gguf filename
        embedding_model_name=$(basename $url_embedding_model)
        # Directly attempt to extract "embedding_name" and fallback to extracting from "embedding" if empty
        embedding_name=$(grep '"embedding_name":' config.json | sed -E 's/.*"embedding_name": *"([^"]*)".*/\1/')
        if [ -z "$embedding_name" ]; then
            embedding_model_stem=$(basename "${url_embedding_model%.*}")
        else
            embedding_model_stem=$embedding_name
        fi

        # parse cli options for embedding vector collection name
        embedding_collection_name=$(awk -F'"' '/"embedding_collection_name":/ {print $4}' config.json)
        if [[ -z "$embedding_collection_name" ]]; then
            embedding_collection_name="default"
        fi
        # parse context size for embedding model
        embedding_ctx_size=$(awk -F'"' '/"embedding_ctx_size":/ {print $4}' config.json)
        # parse batch size for embedding model
        embedding_batch_size=$(awk -F'"' '/"embedding_batch_size":/ {print $4}' config.json)
        # parse ubatch size for embedding model
        if grep -q '"embedding_ubatch_size":' config.json; then
            embedding_ubatch_size=$(awk -F'"' '/"embedding_ubatch_size":/ {print $4}' config.json)
        else
            embedding_ubatch_size=$embedding_batch_size
        fi
        # parse port for LlamaEdge API Server
        llamaedge_port=$(awk -F'"' '/"llamaedge_port":/ {print $4}' config.json)
        # check port
        if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            if lsof -Pi :$llamaedge_port -sTCP:LISTEN -t >/dev/null ; then
                error "    Port $llamaedge_port is in use. Exit ..."
                exit 1
            fi
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
            error "For Windows users, please run this script in WSL. Exit ..."
            exit 1
        else
            error "Only support Linux, MacOS and Windows. Exit ..."
            exit 1
        fi

        cd $gaianet_base_dir
        llamaedge_wasm="$gaianet_base_dir/llama-api-server.wasm"
        if [ ! -f "$llamaedge_wasm" ]; then
            error "Not found llama-api-server.wasm in $gaianet_base_dir\n"
            exit 1
        fi

        # command to start LlamaEdge API Server
        cd $gaianet_base_dir
        cmd=(wasmedge --dir .:./dashboard \
        --env NODE_VERSION=$installer_version \
        --nn-preload default:GGML:AUTO:$chat_model_name \
        --nn-preload embedding:GGML:AUTO:$embedding_model_name \
        llama-api-server.wasm \
        --model-name $chat_model_stem,$embedding_model_stem \
        --ctx-size $chat_ctx_size,$embedding_ctx_size \
        --batch-size $chat_batch_size,$embedding_batch_size \
        --ubatch-size $chat_ubatch_size,$embedding_ubatch_size \
        --prompt-template $prompt_type,embedding \
        --include-usage \
        --web-ui ./ \
        --socket-addr 0.0.0.0:$llamaedge_port)

        if $use_supervise; then
            cmd_string=""
            for i in "${cmd[@]}"; do
                if [[ $i == *" "* ]]; then
                    cmd_string+=\""$i"\"
                else
                    cmd_string+="$i"
                fi
                cmd_string+=" "
            done
        fi

        # Add reverse prompt if it exists
        if [ -n "$reverse_prompt" ]; then
            cmd+=("--reverse-prompt" "$reverse_prompt")

            if $use_supervise; then
                cmd_string+="--reverse-prompt \"$reverse_prompt\" "
            fi
        fi

        printf "    Run the following command to start the LlamaEdge API Server:\n\n"
        for i in "${cmd[@]}"; do
            if [[ $i == *" "* ]]; then
                printf "\"%s\" " "$i"
            else
                printf "%s " "$i"
            fi
        done
        printf "\n\n"

        if $use_supervise; then
            # create `run` file for supervise
            echo '#!/bin/bash' > $gaianet_base_dir/run
            echo $cmd_string >> $gaianet_base_dir/run
            chmod u+x $gaianet_base_dir/run
        fi

        # start api-server
        retry_count=0
        max_retries=3
        while true; do

            # start api-server
            if $use_supervise; then
                # start LlamaEdge API Server with supervise
                if [ "$local_log_storage" -eq 1 ]; then
                    nohup supervise $gaianet_base_dir > $log_dir/start-llamaedge.log 2>&1 &
                else
                    nohup supervise $gaianet_base_dir | vector --config $gaianet_base_dir/vector.toml > $log_dir/vector.log 2>&1 &
                fi
                sleep 2
                supervise_pid=$!
                echo $supervise_pid > $gaianet_base_dir/supervise.pid
                info "    Daemotools-Supervise started with pid: $supervise_pid"

                # Get the status of the service
                status=$(svstat $gaianet_base_dir)
                # Extract the PID from the status
                llamaedge_pid=$(echo $status | awk '{print $4}' | tr -d ')')
                # The reason of incrementing the PID by 1 is that the PID returned by `svstat` is less 1 than the PID returned by `pgrep`
                llamaedge_pid=$((llamaedge_pid + 1))
                echo $llamaedge_pid > $gaianet_base_dir/llamaedge.pid
                info "    LlamaEdge-RAG API Server started with pid: $llamaedge_pid"

            else
                # start LlamaEdge API Server with nohup
                if [ "$local_log_storage" -eq 1 ]; then
                    nohup "${cmd[@]}" > $log_dir/start-llamaedge.log 2>&1 &
                else
                    nohup "${cmd[@]}" | vector --config $gaianet_base_dir/vector.toml > $log_dir/vector.log 2>&1 &
                fi
                sleep 2
                llamaedge_pid=$!
                echo $llamaedge_pid > $gaianet_base_dir/llamaedge.pid
                info "    LlamaEdge API Server started with pid: $llamaedge_pid"
            fi

            sleep 10
            info "    Verify the LlamaEdge API Server. Please wait seconds ..."
            if [[ "$prompt_type" == *"tool"* ]]; then
                status_code=$(curl -o /dev/null -s -w "%{http_code}\n" \
                    -X POST http://localhost:$llamaedge_port/v1/chat/completions \
                    -H 'accept:application/json' \
                    -H 'Content-Type: application/json' \
                    -d "{\"messages\":[{\"role\":\"user\", \"content\": \"What is your name?\"}], \"tools\":[{\"type\":\"function\",\"function\":{\"name\":\"get_name\",\"description\":\"Return your name\"}}], \"model\":\"$chat_model_stem\"}")
            else
                status_code=$(curl -o /dev/null -s -w "%{http_code}\n" \
                    -X POST http://localhost:$llamaedge_port/v1/chat/completions \
                    -H 'accept:application/json' \
                    -H 'Content-Type: application/json' \
                    -d "{\"messages\":[{\"role\":\"user\", \"content\": \"What is your name?\"}], \"model\":\"$chat_model_stem\"}")
            fi

            curl_exit_status=$?

            if [ $curl_exit_status -eq 0 ] && [ "$status_code" -eq 200 ]; then
                info "    * LlamaEdge API Server is ready."
                break
            else
                tail -2 $log_dir/start-llamaedge.log

                # stop supervise if it is running
                if svok $gaianet_base_dir > /dev/null 2>&1; then
                    svc -d $gaianet_base_dir
                    svc -k $gaianet_base_dir
                    svc -x $gaianet_base_dir
                    supervise_pid=$gaianet_base_dir/supervise.pid
                    if [ -f $supervise_pid ]; then
                        rm $supervise_pid
                    fi
                    rm $gaianet_base_dir/run
                    rm -rf $gaianet_base_dir/supervise
                fi

                # stop the api-server
                pkill -9 wasmedge || true

                # remove the pid file
                llamaedge_pid=$gaianet_base_dir/llamaedge.pid
                if [ -f $llamaedge_pid ]; then
                    rm $llamaedge_pid
                fi

                sleep 10  # wait for 10 seconds before retrying

                ((retry_count++))
                if [ $retry_count -ge $((max_retries + 1)) ]; then
                    error "    * Failed to start LlamaEdge API Server after $max_retries retries. Exiting ..."

                    # wait for 3 seconds before exiting
                    sleep 3

                    exit 1
                else
                    error "    * Failed to start LlamaEdge API Server. Retrying ($retry_count)..."
                fi
            fi

        done

    fi

    # 3. start gaia-frp
    if [ "$local_only" -eq 0 ]; then
        # start gaia-frp
        printf "[+] Starting gaia-frp ...\n\n"
        nohup $gaianet_base_dir/bin/frpc -c $gaianet_base_dir/gaia-frp/frpc.toml > $log_dir/start-gaia-frp.log 2>&1 &
        sleep 2
        gaia_frp_pid=$!
        echo $gaia_frp_pid > $gaianet_base_dir/gaia-frp.pid
        info "    gaia-frp started with pid: $gaia_frp_pid"

        # Extract the subdomain from frpc.toml
        subdomain=$(grep "subdomain" $gaianet_base_dir/gaia-frp/frpc.toml | cut -d'=' -f2 | tr -d ' "')

        domain=$(awk -F'"' '/"domain":/ {print $4}' $gaianet_base_dir/config.json)
        info "    The GaiaNet node is started at: https://$subdomain.$domain"
    fi
    if [ "$local_only" -eq 1 ]; then
        printf "    The GaiaNet node is started in local mode at: http://localhost:$llamaedge_port\n\n"
    fi


    # 4. start server assistant
    printf "[+] Starting Server Assistant ...\n\n"
    sleep 2

    # parse system prompt
    system_prompt=$(awk -F'"' '/"system_prompt":/ {print $4}' $gaianet_base_dir/config.json)
    # parse rag prompt
    rag_prompt=$(awk -F'"' '/"rag_prompt":/ {print $4}' $gaianet_base_dir/config.json)

    # start assistant
    export RUST_LOG=info
    nohup $gaianet_base_dir/bin/gaias --server-socket-addr 127.0.0.1:$llamaedge_port --gaianet-dir $gaianet_base_dir --log $gaianet_base_dir/log/assistant.log --interval 60 > /dev/null 2>&1 &

    sleep 2

    # capture the pid of the assistant
    gaias_pid=$!

    # capture the exit status
    status=$?

    echo $gaias_pid > $gaianet_base_dir/gaias.pid

    # check if the assistant has started successfully
    if [ $status -ne 0 ]; then
        error "    * Failed to start Server Assistant. Exiting ..."

        # stop the running services
        stop_force

        exit 1
    else
        info "    Server assistant started with pid: $gaias_pid"
    fi

    info ">>> To stop the GaiaNet node, run the command: gaianet stop <<<"
    info ">>> You can close this terminal window safely now <<<"

    exit 0
}

# * stop subcommand

# deprecated: stop the Qdrant instance, rag-api-server, and gaia-frp
stop() {
    # Check if "gaianet" directory exists in $HOME
    if [ ! -d "$gaianet_base_dir" ]; then
        printf "Not found $gaianet_base_dir\n"
        exit 1
    fi

    # stop the Qdrant instance
    qdrant_pid=$gaianet_base_dir/qdrant.pid
    if [ -f $qdrant_pid ]; then
        printf "[+] Stopping Qdrant instance ...\n"
        kill -9 $(cat $qdrant_pid)
        rm $qdrant_pid
    fi

    # stop api-server
    if svok $gaianet_base_dir > /dev/null 2>&1; then
        # stop supervise
        printf "[+] Stopping Daemontools-Supervise ...\n"
        svc -d $gaianet_base_dir
        svc -k $gaianet_base_dir
        svc -x $gaianet_base_dir
        supervise_pid=$gaianet_base_dir/supervise.pid
        if [ -f $supervise_pid ]; then
            # kill -9 $(cat $supervise_pid)
            rm $supervise_pid
        fi
        rm $gaianet_base_dir/run
        rm -rf $gaianet_base_dir/supervise

        # stop api-server
        llamaedge_pid=$gaianet_base_dir/llamaedge.pid
        if [ -f $llamaedge_pid ]; then
            printf "[+] Stopping API server ...\n"
            kill -9 $(cat $llamaedge_pid)
            rm $llamaedge_pid
        fi

    else
        # stop api-server
        llamaedge_pid=$gaianet_base_dir/llamaedge.pid
        if [ -f $llamaedge_pid ]; then
            printf "[+] Stopping API server ...\n"
            kill -9 $(cat $llamaedge_pid)
            rm $llamaedge_pid
        fi
    fi

    # stop gaia-frp
    gaia_frp_pid=$gaianet_base_dir/gaia-frp.pid
    if [ -f $gaia_frp_pid ]; then
        printf "[+] Stopping gaia-frp ...\n"
        kill -9 $(cat $gaia_frp_pid)
        rm $gaia_frp_pid
    fi

    exit 0
}

# force stop the Qdrant instance, rag-api-server, and gaia-frp
stop_force() {
    local_log_storage=1
    if command -v vector > /dev/null 2>&1 && [ -f $gaianet_base_dir/vector.toml ]; then
        local_log_storage=0
    fi

    printf "[+] Stopping WasmEdge, Qdrant and frpc ...\n"

    if command -v supervise &> /dev/null; then
        # stop supervise if it is running
        if svok $gaianet_base_dir > /dev/null 2>&1; then
            svc -d $gaianet_base_dir
            svc -k $gaianet_base_dir
            svc -x $gaianet_base_dir
            supervise_pid=$gaianet_base_dir/supervise.pid
            if [ -f $supervise_pid ]; then
                rm $supervise_pid
            fi
            rm $gaianet_base_dir/run
            rm -rf $gaianet_base_dir/supervise
        fi
    fi

    pkill -9 qdrant || true
    pkill -9 gaias || true
    pkill -9 wasmedge || true
    if [ "$local_log_storage" -eq 0 ]; then
        pkill -9 vector || true
    fi
    pkill -9 frpc || true

    qdrant_pid=$gaianet_base_dir/qdrant.pid
    if [ -f $qdrant_pid ]; then
        rm $qdrant_pid
    fi

    gaias_pid=$gaianet_base_dir/gaias.pid
    if [ -f $gaias_pid ]; then
        rm $gaias_pid
    fi

    llamaedge_pid=$gaianet_base_dir/llamaedge.pid
    if [ -f $llamaedge_pid ]; then
        rm $llamaedge_pid
    fi

    vector_pid=$gaianet_base_dir/vector.pid
    if [ -f $vector_pid ]; then
        rm $vector_pid
    fi

    gaia_frp_pid=$gaianet_base_dir/gaia-frp.pid
    if [ -f $gaia_frp_pid ]; then
        rm $gaia_frp_pid
    fi

    exit 0
}

# * info subcommand

# show device_id and node_id
show_info() {
    # check the validity of the config.json file
    check_config_options

    # print node_id
    node_id=$(awk -F'"' '/"address":/ {print $4}' $gaianet_base_dir/config.json)
    if [ -z "$node_id" ]; then
        warning "Node id is not assigned. Please run 'gaianet init' command first."
    else
        info "Node ID: $node_id"
    fi

    frpc_toml=$gaianet_base_dir/gaia-frp/frpc.toml
    # check if frpc.toml exists or not
    if [ ! -f "$frpc_toml" ]; then
        error "Not found frpc.toml file in $gaianet_base_dir/gaia-frp"
        exit 1
    fi
    # print device_id
    device_id=$(grep 'metadatas.deviceId' "$frpc_toml" | awk -F' = ' '{print $2}' | tr -d '"')
    if [ -z "$device_id" ]; then
        warning "Devide id is not assigned. Please run 'gaianet init' command first."
    else
        info "Device ID: $device_id"
    fi

}

# * help option

show_help() {
    printf "Usage: gaianet {config|init|run|stop|OPTIONS} \n\n"
    printf "Subcommands:\n"
    printf "  config             Update the configuration.\n"
    printf "  init               Initialize the GaiaNet node.\n"
    printf "  run|start          Start the GaiaNet node.\n"
    printf "  stop               Stop the GaiaNet node.\n"
    printf "  info               Show the device_id and node_id.\n\n"
    printf "Options:\n"
    printf "  --version          Show the version of GaiaNet CLI Tool.\n"
    printf "  --help             Show this help message\n\n"
}

show_config_help() {
    printf "Usage: gaianet config [OPTIONS] \n\n"
    printf "Options:\n"
    printf "  --chat-url <url>               Update the url of chat model.\n"
    printf "  --chat-ctx-size <val>          Update the context size of chat model.\n"
    printf "  --chat-batch-size <val>        Update the batch size of chat model.\n"
    printf "  --chat-ubatch-size <val>       Update the ubatch size of chat model.\n"
    printf "  --embedding-url <url>          Update the url of embedding model.\n"
    printf "  --embedding-ctx-size <val>     Update the context size of embedding model.\n"
    printf "  --embedding-batch-size <val>   Update the batch size of embedding model.\n"
    printf "  --embedding-ubatch-size <val>  Update the ubatch size of embedding model.\n"
    printf "  --prompt-template <val>        Update the prompt template of chat model.\n"
    printf "  --port <val>                   Update the port of LlamaEdge API Server.\n"
    printf "  --system-prompt <val>          Update the system prompt.\n"
    printf "  --rag-prompt <val>             Update the rag prompt.\n"
    printf "  --rag-policy <val>             Update the rag policy [Possible values: system-message, last-user-message].\n"
    printf "  --reverse-prompt <val>         Update the reverse prompt.\n"
    printf "  --domain <val>                 Update the domain of GaiaNet node.\n"
    printf "  --snapshot <url>               Update the Qdrant snapshot.\n"
    printf "  --qdrant-limit <val>           Update the max number of result to return.\n"
    printf "  --qdrant-score-threshold <val> Update the minimal score threshold for the result.\n"
    printf "  --context-window <val>         Update the context window.\n"
    printf "  --base <path>                  The base directory of GaiaNet node.\n"
    printf "  --help                         Show this help message\n\n"
}

show_init_help() {
    printf "Usage: gaianet init [OPTIONS] \n\n"
    printf "Options:\n"
    printf "  --config <val|url>         Name of a pre-defined GaiaNet config or a url. Possible values: default, paris_guide, mua, gaia.\n"
    printf "  --base <path>              The base directory of GaiaNet.\n"
    printf "  --help                     Show this help message\n\n"
}

show_start_help() {
    printf "Usage: gaianet start|run [OPTIONS] \n\n"
    printf "Options:\n"
    printf "  --local-only               Start the program in local mode.\n"
    printf "  --base <path>              The base directory of GaiaNet.\n"
    printf "  --force-rag                Force start rag-api-server even if the 'snapshot' field of config.json is empty. Users should ensure the qdrant has been initialized with the desired snapshot.\n"
    printf "  --help                     Show this help message\n\n"
}

show_stop_help() {
    printf "Usage: gaianet stop [OPTIONS] \n\n"
    printf "Options:\n"
    printf "  --base <path>              The base directory of GaiaNet.\n"
    printf "  --help                     Show this help message\n\n"
}

show_info_help() {
    printf "Usage: gaianet info [OPTIONS] \n\n"
    printf "Options:\n"
    printf "  --base <path>              The base directory of GaiaNet.\n"
    printf "  --help                     Show this help message\n\n"
}

# * main
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

subcommand=$1
shift

case $subcommand in
    --help)
        show_help
        ;;
    --version)
        echo "GaiaNet CLI Tool v$version"
        ;;
    config)
        chat_ctx_size=""
        chat_url=""
        chat_batch_size=""
        embedding_ctx_size=""
        embedding_url=""
        embedding_batch_size=""
        prompt_template=""
        port=""
        system_prompt=""
        rag_prompt=""
        rag_policy=""
        reverse_prompt=""
        domain=""
        snapshot="placeholder"
        qdrant_limit=""
        qdrant_score_threshold=""
        context_window=""

        while (( "$#" )); do
            case "$1" in
                --chat-url)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        chat_url=$2
                        shift 2
                    fi
                    ;;
                --chat-ctx-size)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        chat_ctx_size=$2
                        shift 2
                    fi
                    ;;
                --chat-batch-size)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        chat_batch_size=$2
                        shift 2
                    fi
                    ;;
                --chat-ubatch-size)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        chat_ubatch_size=$2
                        shift 2
                    fi
                    ;;
                --embedding-url)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        embedding_url=$2
                        shift 2
                    fi
                    ;;
                --embedding-ctx-size)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        embedding_ctx_size=$2
                        shift 2
                    fi
                    ;;
                --embedding-batch-size)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        embedding_batch_size=$2
                        shift 2
                    fi
                    ;;
                --embedding-ubatch-size)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        embedding_ubatch_size=$2
                        shift 2
                    fi
                    ;;
                --prompt-template)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        prompt_template=$2
                        shift 2
                    fi
                    ;;
                --port)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        port=$2
                        shift 2
                    fi
                    ;;
                --system-prompt)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        system_prompt=$2
                        shift 2
                    fi
                    ;;
                --rag-prompt)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        rag_prompt=$2
                        shift 2
                    fi
                    ;;
                --rag-policy)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        rag_policy=$2
                        shift 2
                    fi
                    ;;
                --reverse-prompt)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        reverse_prompt=$2
                        shift 2
                    fi
                    ;;
                --domain)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        domain=$2
                        shift 2
                    fi
                    ;;
                --snapshot)
                    new_value=$2
                    # Check if new_value is empty
                    if [ -z "$new_value" ]; then
                        snapshot=""
                        shift 2
                    elif [ ${2:0:1} != "-" ]; then
                        snapshot=$2
                        shift 2
                    fi
                    ;;
                --qdrant-limit)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        qdrant_limit=$2
                        shift 2
                    fi
                    ;;
                --qdrant-score-threshold)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        qdrant_score_threshold=$2
                        shift 2
                    fi
                    ;;
                --context-window)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        context_window=$2
                        shift 2
                    fi
                    ;;
                --base)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        gaianet_base_dir=$2
                        shift 2
                        check_base_dir
                    fi
                    ;;
                *)
                    show_config_help
                    exit 1
                    ;;
            esac
        done

        printf "\n"

        # update url of chat model
        if [ -n "$chat_url" ]; then
            printf "[+] Updating the url of chat model ...\n"
            printf "    * Old url: $(awk -F'"' '/"chat":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New url: $chat_url"

            # update
            update_config chat $chat_url
        fi

        # update context size of chat model
        if [ -n "$chat_ctx_size" ]; then
            printf "[+] Updating the context size of chat model ...\n"
            printf "    * Old size: $(awk -F'"' '/"chat_ctx_size":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New size: $chat_ctx_size"

            # update
            update_config chat_ctx_size $chat_ctx_size
        fi

        # update batch size of chat model
        if [ -n "$chat_batch_size" ]; then
            printf "[+] Updating the batch size of chat model ...\n"
            printf "    * Old size: $(awk -F'"' '/"chat_batch_size":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New size: $chat_batch_size"

            # update
            update_config chat_batch_size $chat_batch_size
        fi

        # update ubatch size of chat model
        if [ -n "$chat_ubatch_size" ]; then
            printf "[+] Updating the ubatch size of chat model ...\n"
            printf "    * Old size: $(awk -F'"' '/"chat_ubatch_size":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New size: $chat_ubatch_size"

            # update
            update_config chat_ubatch_size $chat_ubatch_size
        fi

        # update url of embedding model
        if [ -n "$embedding_url" ]; then
            printf "[+] Updating the url of embedding model ...\n"
            printf "    * Old url: $(awk -F'"' '/"embedding":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New url: $embedding_url"

            # update
            update_config embedding $embedding_url
        fi

        # update context size of embedding model
        if [ -n "$embedding_ctx_size" ]; then
            printf "[+] Updating the context size of embedding model ...\n"
            printf "    * Old size: $(awk -F'"' '/"embedding_ctx_size":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New size: $embedding_ctx_size"

            # update
            update_config embedding_ctx_size $embedding_ctx_size
        fi

        # update batch size of embedding model
        if [ -n "$embedding_batch_size" ]; then
            printf "[+] Updating the batch size of embedding model ...\n"
            printf "    * Old size: $(awk -F'"' '/"embedding_batch_size":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New size: $embedding_batch_size"

            # update
            update_config embedding_batch_size $embedding_batch_size
        fi

        # update ubatch size of embedding model
        if [ -n "$embedding_ubatch_size" ]; then
            printf "[+] Updating the ubatch size of embedding model ...\n"
            printf "    * Old size: $(awk -F'"' '/"embedding_ubatch_size":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New size: $embedding_ubatch_size"

            # update
            update_config embedding_ubatch_size $embedding_ubatch_size
        fi

        # update prompt template
        if [ -n "$prompt_template" ]; then
            printf "[+] Updating the prompt template of chat model ...\n"
            printf "    * Old template: $(awk -F'"' '/"prompt_template":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New template: $prompt_template"

            # update
            update_config prompt_template $prompt_template
        fi

        # update prompt template
        if [ -n "$reverse_prompt" ]; then
            printf "[+] Updating the reverse prompt of chat model ...\n"
            printf "    * Old template: $(awk -F'"' '/"reverse_prompt":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New template: $reverse_prompt"

            # update
            update_config reverse_prompt $reverse_prompt
        fi

        # update port
        if [ -n "$port" ]; then
            printf "[+] Updating the port of LlamaEdge API Server ...\n"
            printf "    * Old port: $(awk -F'"' '/"llamaedge_port":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New port: $port"

            # update
            update_config llamaedge_port $port
        fi

        # update system prompt
        if [ -n "$system_prompt" ]; then
            printf "[+] Updating the system prompt of chat model ...\n"
            printf "    * Old system prompt: $(awk -F'"' '/"system_prompt":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New system prompt: $system_prompt"
            # The new value for system_prompt
            new_value="$system_prompt"

            # Escape ampersands and backslashes in the new value
            new_value_escaped=$(echo "$new_value" | sed 's/[&\\/]/\\&/g')

            # Update the value of system_prompt in config.json
            sed_in_place "s|\"system_prompt\": \".*\"|\"system_prompt\": \"$new_value_escaped\"|" $gaianet_base_dir/config.json
        fi

        # update rag prompt
        if [ -n "$rag_prompt" ]; then
            printf "[+] Updating the rag prompt of chat model ...\n"
            printf "    * Old port: $(awk -F'"' '/"rag_prompt":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New rag prompt: $rag_prompt"

            # The new value for rag_prompt
            new_value="$rag_prompt"

            # Escape ampersands and backslashes in the new value
            new_value_escaped=$(echo "$new_value" | sed 's/[&\\/]/\\&/g')

            # Update the value of rag_prompt in config.json
            sed_in_place "s|\"rag_prompt\": \".*\"|\"rag_prompt\": \"$new_value_escaped\"|" $gaianet_base_dir/config.json
        fi

        # update rag policy
        if [ -n "$rag_policy" ]; then
            printf "[+] Updating the rag policy of GaiaNet node ...\n"
            printf "    * Old rag policy: $(awk -F'"' '/"rag_policy":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New rag policy: $rag_policy"

            # update
            update_config rag_policy $rag_policy
        fi

        # update domain
        if [ -n "$domain" ]; then
            printf "[+] Updating the domain of GaiaNet node ...\n"
            printf "    * Old domain: $(awk -F'"' '/"domain":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New domain: $domain"

            # update
            update_config domain $domain
        fi

        # update url of snapshot
        if [ -z "$snapshot" ] || [ "$snapshot" != "placeholder" ]; then
            printf "[+] Updating the url of snapshot ...\n"
            printf "    * Old url: $(awk -F'"' '/"snapshot":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New url: $snapshot"

            # update
            update_config snapshot $snapshot
        fi

        # update qdrant limit
        if [ -n "$qdrant_limit" ]; then
            printf "[+] Updating the qdrant limit ...\n"
            printf "    * Old limit: $(awk -F'"' '/"qdrant_limit":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New limit: $qdrant_limit"

            # update
            update_config qdrant_limit $qdrant_limit
        fi

        # update qdrant score threshold
        if [ -n "$qdrant_score_threshold" ]; then
            printf "[+] Updating the qdrant score threshold ...\n"
            printf "    * Old threshold: $(awk -F'"' '/"qdrant_score_threshold":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New threshold: $qdrant_score_threshold"

            # update
            update_config qdrant_score_threshold $qdrant_score_threshold
        fi

        # update context window
        if [ -n "$context_window" ]; then
            printf "[+] Updating the context window ...\n"
            printf "    * Old window: $(awk -F'"' '/"context_window":/ {print $4}' $gaianet_base_dir/config.json)\n"
            info "    * New window: $context_window"

            # update
            update_config context_window $context_window
        fi

        printf "[+] COMPLETED! The config.json is updated successfully.\n\n"

        exit 0
        ;;

    init)
        config=""

        while (( "$#" )); do
            case "$1" in
                --config)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        config=$2
                        shift 2
                    fi
                    ;;
                --base)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        gaianet_base_dir=$2
                        shift 2
                        check_base_dir
                    fi
                    ;;
                *)
                    show_init_help
                    exit 1
                    ;;
            esac
        done

        case $config in
            "")
                init
                ;;
            paris_guide)
                printf "[+] Downloading config.json ...\n"
                config_url="https://raw.githubusercontent.com/GaiaNet-AI/gaianet-node/main/config.json"
                printf "    Url: $config_url\n"
                curl --retry 3 --progress-bar -L $config_url -o $gaianet_base_dir/config.json
                info "    The config.json of Paris Guide is downloaded in $gaianet_base_dir"

                # init
                init
                ;;
            mua)
                printf "[+] Downloading config.json ...\n"
                config_url="https://raw.githubusercontent.com/alabulei1/test-ports/main/mua/config.json"
                printf "    Url: $config_url\n"
                curl --retry 3 --progress-bar -L $config_url -o $gaianet_base_dir/config.json
                info "    The config.json of mua is downloaded in $gaianet_base_dir"

                # init
                init
                ;;
            gaia)
                printf "[+] Downloading config.json ...\n"
                config_url="https://raw.githubusercontent.com/alabulei1/test-ports/main/gaianet/config.json"
                printf "    Url: $config_url\n"
                curl --retry 3 --progress-bar -L $config_url -o $gaianet_base_dir/config.json
                info "    The config.json of gaia is downloaded in $gaianet_base_dir"

                # init
                init
                ;;
            *)
                # if config is a url
                if [[ $config == http* ]]; then
                    printf "[+] Downloading config.json ...\n"
                    printf "    Url: $config\n"
                    curl --retry 3 --progress-bar -L $config -o $gaianet_base_dir/config.json
                    info "    The config.json is downloaded in $gaianet_base_dir"

                    # init
                    init
                else
                    show_init_help
                    exit 1
                fi
                ;;
        esac

        ;;
    run|start)
        local=0

	force_rag=false

        while (( "$#" )); do
            case "$1" in
                --local-only)
                    local=1
                    shift
                    ;;
                --base)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        gaianet_base_dir=$2
                        shift 2
                        check_base_dir
                    fi
                    ;;
                --force-rag)
                    force_rag=true
                    shift
                    ;;
                *)
                    show_start_help
                    exit 1
                    ;;
            esac
        done

        start $local $force_rag

        ;;

    stop)
        while (( "$#" )); do
            case "$1" in
                --base)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        gaianet_base_dir=$2
                        shift 2
                        check_base_dir
                    fi
                    ;;
                *)
                    show_stop_help
                    exit 1
                    ;;
            esac
        done

        stop_force

        ;;
    info)
        while (( "$#" )); do
            case "$1" in
                --base)
                    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                        gaianet_base_dir=$2
                        shift 2
                        check_base_dir
                    fi
                    ;;
                *)
                    show_info_help
                    exit 1
                    ;;
            esac
        done

        show_info

        ;;
    *)
        show_help
        exit 1
esac

exit 0
