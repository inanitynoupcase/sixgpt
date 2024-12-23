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

    # Create a .env file in the miner directory
    cat <<EOF > "$MINER_DIR/.env"
VANA_PRIVATE_KEY=$PRIVATE_KEY
VANA_NETWORK=mainnet
OLLAMA_API_URL=http://ollama_$i:$OLLAMA_PORT/api
EOF

    # Create a docker-compose.yml file for each miner
    cat <<EOF > "$MINER_DIR/docker-compose.yml"
version: '3.8'

services:
  ollama_$i:
    image: ollama/ollama:0.3.12
    ports:
      - "$((OLLAMA_PORT + i)):$OLLAMA_PORT"
    volumes:
      - ollama:/root/.ollama
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  sixgpt3_$i:
    image: sixgpt/miner:latest
    ports:
      - "$((START_PORT + i)):$START_PORT"
    depends_on:
      - ollama_$i
    environment:
      - VANA_PRIVATE_KEY=\${VANA_PRIVATE_KEY}
      - VANA_NETWORK=\${VANA_NETWORK}
      - OLLAMA_API_URL=\${OLLAMA_API_URL}
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  ollama:
EOF

    # Navigate to the miner directory and run docker-compose
    (
        cd "$MINER_DIR"
        docker-compose up -d
    )

    echo "Miner $i setup completed: $MINER_DIR with ports $((START_PORT + i)) and $((OLLAMA_PORT + i))"
    i=$((i + 1))
done < "$PRIVATE_KEYS_FILE"
