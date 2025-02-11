#!/bin/bash
# Set max timeout (in seconds)
MAX_TIMEOUT=180  # 3 minutes

# Set retry interval (in seconds)
RETRY_INTERVAL=5

# Compute Key Vault URL
KEY_VAULT_URL="https://${KEY_VAULT_NAME}.vault.azure.net/"

# Track start time
START_TIME=$(date +%s)

echo "Checking Key Vault availability: $KEY_VAULT_URL"
echo "Timeout set to $MAX_TIMEOUT seconds"

while true; do
    # Attempt to curl the Key Vault endpoint
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$KEY_VAULT_URL")

    # Check if response is HTTP 200 (Success)
    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo "Key Vault is accessible! HTTP Status: $HTTP_STATUS"
        exit 0
    fi

    # Get current time
    CURRENT_TIME=$(date +%s)

    # Check if timeout has been reached
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    if [[ "$ELAPSED_TIME" -ge "$MAX_TIMEOUT" ]]; then
        echo "Timeout reached ($MAX_TIMEOUT seconds). Key Vault is still unreachable."
        exit 1
    fi

    echo "Key Vault not reachable yet (HTTP: $HTTP_STATUS). Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done
