#!/bin/bash

# File containing the private keys
PRIVATE_KEYS_FILE="privatekey_sixgpt.txt"

# Starting ports
START_PORT=3000
OLLAMA_PORT=11434

# Read each line from the privatekey_sixgpt.txt file
i=1
while IFS= read -r PRIVATE_KEY; do
    # Create a separate directory for each miner
    MINER_DIR="miner_$i"
    mkdir -p "$MINER_DIR"

    # Copy the contents of the repository into the miner directory
    cp -r miner/* "$MINER_DIR"

    # Create a .env file in the miner directory
    cat <<EOF > "$MINER_DIR/.env"
VANA_PRIVATE_KEY=$PRIVATE_KEY
VANA_NETWORK=mainnet
OLLAMA_API_URL=http://ollama_$i:$OLLAMA_PORT/api
EOF

    # Modify the docker-compose.yml file for each miner
    sed "s/11439:11434/$((OLLAMA_PORT + i)):11434/g; s/3000:3000/$((START_PORT + i)):3000/g; s/ollama:/ollama_$i:/g; s/sixgpt3:/sixgpt3_$i:/g" miner/docker-compose.yml > "$MINER_DIR/docker-compose.yml"

    # Navigate to the miner directory and run docker-compose
    (
        cd "$MINER_DIR"
        docker-compose up -d
    )

    echo "Miner $i setup completed: $MINER_DIR with ports $((START_PORT + i)) and $((OLLAMA_PORT + i))"
    i=$((i + 1))
done < "$PRIVATE_KEYS_FILE"
