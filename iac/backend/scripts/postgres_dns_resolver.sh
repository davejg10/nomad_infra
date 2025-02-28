#!/bin/bash
# This script is used when deploying the infra stack. It ensures the agent (which is self hosted within our network) can resolve the name of the Postgres flexible server
# By polling for this, we ensure that we can connect to the DB using the FQDN of the server

$PSQL_FQDN=${POSTGRES_FQDN}
# Set max timeout (in seconds)
MAX_TIMEOUT=180  # 3 minutes

# Set retry interval (in seconds)
RETRY_INTERVAL=5

# Track start time
START_TIME=$(date +%s)

echo "Checking Postgres Flexible Server availability: $PSQL_FQDN"
echo "Timeout set to $MAX_TIMEOUT seconds"

while true; do
    # Attempt to nslookup the Key Vault private endpoint
    NSLOOKUP_RESULT=$(nslookup "$PSQL_FQDN")
    
    # Check if nslookup was successful by looking for "Non-authoritative answer"
    if [[ $? -eq 0 ]]; then
        echo "Postgres Server is accessible! NSLookup result: $NSLOOKUP_RESULT"
        sleep 5
        exit 0
    fi

    # Get current time
    CURRENT_TIME=$(date +%s)

    # Check if timeout has been reached
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    if [[ "$ELAPSED_TIME" -ge "$MAX_TIMEOUT" ]]; then
        echo "Timeout reached ($MAX_TIMEOUT seconds). Postgres Server is still unreachable."
        exit 1
    fi

    echo "Postgres Server not reachable yet (nslookup result: $NSLOOKUP_RESULT). Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done
