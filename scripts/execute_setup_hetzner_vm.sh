#!/bin/bash
# Run this script locally. The Hetzner Service principal exists in Azure with the name sp-<env>-hetzner-scraper

SETUP_HETZNER_VM_SCRIPT="setup_hetzner_vm.sh"

HETZNER_SP_CLIENT_SECRET=$1
ENV=$2

HETZNER_USER="root"
HETZNER_IP="95.217.9.73"

HETZNER_SP_CLIENT_ID=$(az ad sp list --display-name "sp-$ENV-hetzner-scraper" --query "[0].appId" -o tsv)

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$HETZNER_IP"

scp -i $HOME/.ssh/hertz -o StrictHostKeyChecking=accept-new ./$SETUP_HETZNER_VM_SCRIPT ${HETZNER_USER}@${HETZNER_IP}:~/

ssh -i $HOME/.ssh/hertz -o StrictHostKeyChecking=accept-new ${HETZNER_USER}@${HETZNER_IP} "chmod +x ~/$SETUP_HETZNER_VM_SCRIPT && ~/$SETUP_HETZNER_VM_SCRIPT '$HETZNER_SP_CLIENT_ID' '$HETZNER_SP_CLIENT_SECRET' '$ENV'"