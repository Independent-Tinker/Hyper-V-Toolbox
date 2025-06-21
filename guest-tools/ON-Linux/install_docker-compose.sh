#!/bin/bash

USE_KALI=false

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" == "-kali" ]]; then
    USE_KALI=true
  fi
done

if $USE_KALI; then
  CODENAME="bookworm"
else
  CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
fi

sudo apt install gnome-terminal

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin