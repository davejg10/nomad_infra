#!/bin/bash

ENV=$1

NOMAD_RG_NAME="rg-$ENV-uks-nomad-01"
WEBAPP_NAME="web-t-$ENV-uks-nomad-01"
APP_PLAN_NAME="asp-$ENV-uks-nomad-01"
VM_NAME="vm-$ENV-uks-nomad-neo4j-01"

# Function to check if a web app exists
check_webapp_exists() {
    az webapp show --name "$1" --resource-group "$2" &> /dev/null
    return $?
}


# Function to check if a VM exists before stopping
check_vm_exists() {
    az vm show --name "$1" --resource-group "$2" &> /dev/null
    return $?
}

echo "Starting cleanup process..."

# Delete Web App if it exists
if check_webapp_exists "$WEBAPP_NAME" "$NOMAD_RG_NAME"; then
    echo "Deleting Web App: $WEBAPP_NAME"
    az webapp delete --name "$WEBAPP_NAME" --resource-group "$NOMAD_RG_NAME"
else
    echo "Web App $WEBAPP_NAME does not exist. Skipping."
fi

# Delete App Service Plan if it exists
if check_webapp_exists "$WEBAPP_NAME" "$NOMAD_RG_NAME"; then
    echo "Deleting App Service Plan: $APP_PLAN_NAME"
    az appservice plan delete --name "$APP_PLAN_NAME" --resource-group "$NOMAD_RG_NAME" -y
else
    echo "App Service Plan $APP_PLAN_NAME does not exist or is not associated with an existing web app. Skipping."
fi

# Stop VM if it exists and is running
if check_vm_exists "$VM_NAME" "$NOMAD_RG_NAME"; then
    echo "Checking VM status..."
   
    echo "Stopping VM: $VM_NAME"
    az vm stop --name "$VM_NAME" --resource-group "$NOMAD_RG_NAME" &> /dev/null

    echo "Deallocating VM: $VM_NAME"
    az vm deallocate --name "$VM_NAME" --resource-group "$NOMAD_RG_NAME" 

else
    echo "VM $VM_NAME does not exist. Skipping."
fi

echo "Cleanup process completed."
