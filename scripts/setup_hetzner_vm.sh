#!/bin/bash

echo "Installing AZ cli"
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

apt-get install docker.io -y
HETZNER_SP_CLIENT_ID=$1
HETZNER_SP_CLIENT_SECRET=$2
ENV=$3

export AZURE_CLIENT_ID=$HETZNER_SP_CLIENT_ID
export AZURE_CLIENT_SECRET=$HETZNER_SP_CLIENT_SECRET
export AZURE_TENANT_ID="49d26886-9fbf-4713-ae64-57780bb580dd"

HOST_LOG_DIR="/opt/myapp/logs"
CONTAINER_LOG_DIR="/app/logs"
echo "Creating host log directory to store logs"
mkdir -p $HOST_LOG_DIR

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

az acr login --name acrglbuksdevopsutils.azurecr.io

docker pull acrglbuksdevopsutils.azurecr.io/nomad-data/one2goasia:latest

echo "Running ONE2GOASIA scraper"
docker run -d -e AZURE_CLIENT_ID="$AZURE_CLIENT_ID" \
              -e AZURE_TENANT_ID="$AZURE_TENANT_ID" \
              -e AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET" \
              -e SPRING_PROFILE="hetzner" \
              -e ENVIRONMENT="$ENV" \
              -v $HOST_LOG_DIR:$CONTAINER_LOG_DIR \
              --label com.centurylinklabs.watchtower.enable=true acrglbuksdevopsutils.azurecr.io/nomad-data/one2goasia:latest

# We use watchtower to poll our ACR and pull any pushes. GitOps is therefore used to pull updates rather than us pushing them.
# We mount the .docker/config.json to give Watchtower authorisation to our ACR.
docker run -d \
            --name watchtower   \
            --restart=always \
            -v $HOME/.docker/config.json:/config.json  \
            -v /var/run/docker.sock:/var/run/docker.sock   \
            containrrr/watchtower \
            --cleanup \
            --label-enable \
            --interval 200 # Check every 200 seconds
