#!/bin/bash

clear 
figlet "WARNING"
echo "This script is meant to prepare system for public build, DO NOT RUN IT, if you don't know what you're doing!"
# Simple script to run prior to compiling a public .iso for new version
sleep 3

clear
echo "Starting process..."

# to be sure
cd

# Make sure skel perms works
sudo chmod -R 755 /etc/skel/.config

# vbox log trash
rm .vbox*

# .conky
sudo rm -rf /etc/skel/.conky
sudo cp -r ~/.conky /etc/skel/.conky

# .config dir
sudo rm -rf /etc/skel/.config
sudo cp -r ~/.config /etc/skel/.config
# Get rid of session files
sudo rm -r /etc/skel/.config/session
#sudo rm -r /etc/skel/.config/chromium

# Szmelc dir
sudo rm -fr /etc/skel/szmelc
sudo cp -r ~/szmelc /etc/skel/szmelc
# bashrc
# sudo rm -fr /etc/skel/.bashrc
# sudo cp ~/.bashrc /etc/skel/.bashrc
sudo rm /etc/skel/.zshrc
sudo cp ~/.zshrc /etc/skel/.zshrc
sudo rm /etc/skel/.p10k.zsh
sudo cp ~/.p10k.zsh /etc/skel/.p10k.zsh
sudo rm /etc/skel/.zcompdump
sudo cp ~/.zcompdump /etc/skel/.zcompdump

sudo rm -fr /etc/skel/.local
sudo cp -r /home/szmelc/.local /etc/skel/.local

# REMOVE USER DATA FROM BROWSER
sudo rm -f /etc/skel/.config/chromium/Default/{Login\ Data*,Cookies,History,History-journal,Web\ Data*,Top\ Sites*,Visited\ Links,Current\ Session,Current\ Tabs,Last\ Session,Last\ Tabs}

# sudo rm -f $HOME/.config/chromium/Default/{Login\ Data*,Cookies,History,History-journal,Web\ Data*,Top\ Sites*,Visited\ Links,Current\ Session,Current\ Tabs,Last\ Session,Last\ Tabs}

sleep 3

# Prompt the user for the Build ID string
read -p "Build ID: " build
echo "$build" | sudo tee /etc/.entropy-build > /dev/null

# Prompt the user for the new version number
read -p "Enter the new version number (e.g., 9): " new_version

# Define the files to update
FILES=("/etc/initrd_release" "/etc/lsb-release")

# Loop through each file and replace vX with the new version
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        # Use sed to replace v8 or any vX with the specified version
        sudo sed -i "s/v[0-9]\+/v$new_version/g" "$FILE"
        echo "Updated version in $FILE to v$new_version"
    else
        echo "$FILE not found."
    fi
done

echo "Complete"

