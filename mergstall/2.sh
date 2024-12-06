#!/bin/bash

source 0.sh

# Set necessary permissions
log "Fixing ownership and permissions..."
chown -R root:root $target_mount_point

# Create szmelc directory
log "Creating szmelc directory at target..."
mkdir -p "$SPAWN"

# Get the list of installed packages from the live ISO
installed_packages=$(chroot "$LIVE_ISO_ROOT" dpkg --get-selections | awk '$2 == "install" {print $1}')

# Output package list to a text file
package_list_file="$SPAWN/packages.txt"
echo "$installed_packages" > "$package_list_file"
log "List of installed packages has been saved to $package_list_file."

# Backup current (live ISO) home directory without extra paths inside the zip
log "Backing up live ISO home directory..."
cd "$LIVE_ISO_ROOT/home" && zip -r "$SPAWN/new-home.zip" * &>> "$LOG_FILE"

# Backup target's original home directory without extra paths inside the zip
log "Backing up target system home directory..."
cd "$target_mount_point/home" && zip -r "$SPAWN/old-home.zip" * &>> "$LOG_FILE"

sleep 5
# STAGE 3
bash 3.sh
