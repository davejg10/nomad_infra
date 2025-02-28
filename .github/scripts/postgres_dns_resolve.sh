#!/bin/bash
# This script is used when deploying the infra stack. It ensures the agent (which is self hosted within our network) can resolve the name of the Key Vault
# By polling for this, we ensure that all resources related to private endpoints are deployed and working, and therefore we can operate on the data plane

# Set max timeout (in seconds)
MAX_TIMEOUT=180  # 3 minutes

# Set retry interval (in seconds)
RETRY_INTERVAL=5

# Compute Key Vault private endpoint FQDN
KEY_VAULT_FQDN="${KEY_VAULT_NAME}.privatelink.vaultcore.azure.net"

# Track start time
START_TIME=$(date +%s)

echo "Checking Key Vault availability: $KEY_VAULT_FQDN"
echo "Timeout set to $MAX_TIMEOUT seconds"

while true; do
    # Attempt to nslookup the Key Vault private endpoint
    NSLOOKUP_RESULT=$(nslookup "$KEY_VAULT_FQDN" | grep "Address" | tail -n 1)
    
    # Check if nslookup was successful by looking for "Non-authoritative answer"
    if [[ "$NSLOOKUP_RESULT" == *"${KEY_VAULT_INTERNAL_IP}"* ]]; then
        echo "Key Vault is accessible! NSLookup result: $NSLOOKUP_RESULT"
        sleep 5
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

    echo "Key Vault not reachable yet (nslookup result: $NSLOOKUP_RESULT). Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done