#!/bin/bash

source 0.sh

# stage 0
mkdir /usr/mergstall #just in case xD

# Minstaller for Entropy stage 1

clear
# Log file to track entire operation
LOG_FILE="/tmp/backup_operation_$(date +%Y%m%d%H%M%S).log"
exec &> >(tee -a "$LOG_FILE")

# Function to log messages with timestamps
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Starting disk layout scan..."

# Display the current disk layout
lsblk | tee -a "$LOG_FILE"

sleep 2

# Function to detect Linux installations
detect_linux_installations() {
    log "Scanning for existing Linux installations..."
    mapfile -t PARTITIONS < <(lsblk -lnpo NAME,TYPE | awk '$2 == "part" {print $1}')
    
    for PARTITION in "${PARTITIONS[@]}"; do
        TEMP_MOUNT="/mnt/scan_$$"
        mkdir -p "$TEMP_MOUNT"
        
        mount "$PARTITION" "$TEMP_MOUNT" &> /dev/null
        if [[ $? -eq 0 ]]; then
            if [[ -f "$TEMP_MOUNT/etc/lsb-release" ]]; then
                DISTRO_NAME=$(grep -oP '^DISTRIB_ID="?\K[^"]+' "$TEMP_MOUNT/etc/lsb-release")
                DISTRO_VERSION=$(grep -oP '^DISTRIB_RELEASE="?\K[^"]+' "$TEMP_MOUNT/etc/lsb-release")
                log "Found Linux installation: $DISTRO_NAME version $DISTRO_VERSION on partition $PARTITION"
            fi
            
            umount "$TEMP_MOUNT"
        fi
        
        rmdir "$TEMP_MOUNT"
    done
}

# Call the function to detect Linux installations
detect_linux_installations

# Ask user to select the partition they want to update
read -p "Please enter the partition (e.g., /dev/sda1) to update: " TARGET_PARTITION

# Verify if the partition exists and can be mounted
if [[ ! -b "$TARGET_PARTITION" ]]; then
    log "Error: Invalid partition. Exiting..."
    exit 1
fi

# Mount the target partition
target_mount_point="/mnt/target"
mkdir -p "$target_mount_point"
mount "$TARGET_PARTITION" "$target_mount_point" || {
    log "Error: Failed to mount target partition. Exiting..."
    exit 1
}

sleep 5
# ====== STAGE 2 ======
bash 2.sh       
       
