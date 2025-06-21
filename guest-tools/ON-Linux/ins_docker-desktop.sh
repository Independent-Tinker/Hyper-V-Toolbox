#!/bin/bash
# Set error handling
set -e
# Function for error handling
handle_error() {
  echo "Error: $1"
  exit 1
} 

# Check for --clean flag to remove old Docker packages
if [[ "$1" == "--clean" ]]; then
  echo "Removing old Docker and related packages..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" || echo "Package $pkg not found or already removed."
  done
fi

# Check if GNOME is running
if ! echo $XDG_CURRENT_DESKTOP | grep -qi gnome; then
  echo "GNOME is not running. Installing gnome-terminal..."
  sudo apt-get update || handle_error "Failed to update package lists"
  sudo apt-get install -y gnome-terminal || handle_error "Failed to install gnome-terminal"
fi

# Add Docker's official GPG key:
echo "Adding Docker's official GPG key..."
sudo apt-get update || handle_error "Failed to update package lists"
sudo apt-get install -y ca-certificates curl || handle_error "Failed to install ca-certificates and curl"
sudo install -m 0755 -d /etc/apt/keyrings || handle_error "Failed to create keyrings directory"
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc || handle_error "Failed to download Docker's GPG key"
sudo chmod a+r /etc/apt/keyrings/docker.asc || handle_error "Failed to set permissions on Docker's GPG key"

# Add the repository to Apt sources:
echo "Adding Docker repository to Apt sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
$(. /etc/os-release && [[ "$VERSION_CODENAME" == "kali-rolling" ]] && echo "bookworm" || echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || handle_error "Failed to add Docker repository"
sudo apt-get update || handle_error "Failed to update package lists"

# Install Docker packages
echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || handle_error "Failed to install Docker packages"

echo "Docker installation completed successfully."
