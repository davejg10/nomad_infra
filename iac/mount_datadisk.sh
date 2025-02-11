#!/bin/bash

NEO4J_DATA_DIR="/datadisk"

# Programatiicaly find datadisk name by suggesting size and mountpoint empty
DATADISK=$(lsblk -d -n -o NAME,SIZE,MOUNTPOINT | awk -v size="${neo4j_data_disk_size_gb}G" '$2 == size  && $3 == "" {print $1}' | head -1)

sudo mkdir $NEO4J_DATA_DIR
# Format disk
sudo mkfs.ext4 /dev/$DATADISK
# Mount disk
sudo mount /dev/$DATADISK $NEO4J_DATA_DIR
# Add to fstab for persistence
echo "/dev/$DATADISK $NEO4J_DATA_DIR ext4 defaults 0 0" | sudo tee -a /etc/fstab