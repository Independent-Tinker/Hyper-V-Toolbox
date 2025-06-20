#!/bin/bash

# Check if GNOME is running
if ! echo $XDG_CURRENT_DESKTOP | grep -qi gnome; then
    echo "GNOME is not running. Installing gnome-terminal..."
    sudo apt-get update
    sudo apt-get install -y gnome-terminal
fi

# Prompt user for apt install
read -p "Do you want to install Docker using apt? (y/n): " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    VERSION_CODENAME=$( . /etc/os-release && echo "$VERSION_CODENAME" )
    if [ -z "$VERSION_CODENAME" ]; then
        echo "Could not determine Debian codename. Exiting."
        exit 1
    fi
    echo "Debian codename is $VERSION_CODENAME. Proceeding with apt install..."
    # Place your apt install commands here
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $VERSION_CODENAME stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    # Download Docker Desktop .deb and install
    DOWNLOAD_DIR="$HOME/Downloads"
    FILE="$DOWNLOAD_DIR/docker-desktop-amd64.deb"
    URL="https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
    mkdir -p "$DOWNLOAD_DIR"
    echo "Downloading Docker Desktop .deb to $FILE..."
    curl -L "$URL" -o "$FILE"
    echo "Installing Docker Desktop..."
    sudo apt-get install -y "$FILE"
fi