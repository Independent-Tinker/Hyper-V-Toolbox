#!/bin/bash
# Enable Hyper-V Enhanced Session Mode for this Debian 12 VM

# Exit immediately if a command exits with a non-zero status
set -e

# Function for error handling
handle_error() {
    echo "ERROR: ${1:-"An unknown error occurred"}" >&2
    exit 1
}

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    handle_error "This script must be run with root privileges"
fi

# Update system
log "Updating system packages..."
apt update || handle_error "Failed to update package information"
apt upgrade -y || handle_error "Failed to upgrade packages"

if [ -f /var/run/reboot-required ]; then
    handle_error "A reboot is required in order to proceed with the install.\nPlease reboot and re-run this script to finish the install."
fi

# Install XRDP
log "Prepping your system for enhanced session mode."
apt install -y xrdp || handle_error "Failed to install XRDP"

log "Stopping XRDP services..."
systemctl stop xrdp xrdp-sesman || handle_error "Failed to stop XRDP services"

# Backup config files
log "Creating backup of configuration files..."
cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak || handle_error "Failed to backup xrdp.ini"
cp /etc/xrdp/sesman.ini /etc/xrdp/sesman.ini.bak || handle_error "Failed to backup sesman.ini"
cp /etc/X11/Xwrapper.config /etc/X11/Xwrapper.config.bak || handle_error "Failed to backup Xwrapper.config"

# Update xrdp.ini for Hyper-V Enhanced Session
log "Configuring XRDP for Hyper-V Enhanced Session..."
sed -i 's/port=3389/port=vsock:\/\/\/-1:3389/g' /etc/xrdp/xrdp.ini || handle_error "Failed to update port configuration"

# Ensure vmconnect=true is set (uncomment or append if missing)
if grep -q '^#vmconnect=true' /etc/xrdp/xrdp.ini; then
    sed -i 's/^#vmconnect=true/vmconnect=true/' /etc/xrdp/xrdp.ini || handle_error "Failed to uncomment vmconnect setting"
elif ! grep -q '^vmconnect=true' /etc/xrdp/xrdp.ini; then
    echo 'vmconnect=true' >> /etc/xrdp/xrdp.ini || handle_error "Failed to add vmconnect setting"
fi

sed -i 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini || handle_error "Failed to update security_layer setting"
sed -i 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini || handle_error "Failed to update crypt_level setting"
sed -i 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini || handle_error "Failed to update bitmap_compression setting"

# Create custom session script for GNOME
log "Creating custom session script for GNOME..."
if [ ! -e /etc/xrdp/startdebian.sh ]; then
    cat > /etc/xrdp/startdebian.sh << 'EOF' || handle_error "Failed to create startdebian.sh"
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=debian
export XDG_CURRENT_DESKTOP=debian:GNOME
exec /etc/xrdp/startwm.sh
EOF
    sed -i '/^DefaultWindowManager=/s/startwm/startdebian/' /etc/xrdp/sesman.ini || handle_error "Failed to update DefaultWindowManager setting"
    chmod a+x /etc/xrdp/startdebian.sh || handle_error "Failed to make startdebian.sh executable"
fi

# Configure sesman.ini to use the custom session script and rename redirected drives
log "Configuring XRDP session manager..."
sed -i 's/startwm/startdebian/g' /etc/xrdp/sesman.ini || handle_error "Failed to update session script in sesman.ini"
sed -i 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini || handle_error "Failed to update FuseMountName in sesman.ini"

# Allow anybody to start X sessions (needed for XRDP)
log "Configuring X server permissions..."
if grep -q '^allowed_users=' /etc/X11/Xwrapper.config; then
    sed -i 's/^allowed_users=.*/allowed_users=anybody/g' /etc/X11/Xwrapper.config || handle_error "Failed to update allowed_users in Xwrapper.config"
else
    echo 'allowed_users=anybody' >> /etc/X11/Xwrapper.config || handle_error "Failed to add allowed_users to Xwrapper.config"
fi

# Ensure hv_sock gets loaded at boot
log "Configuring Hyper-V socket module..."
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
    echo "hv_sock" > /etc/modules-load.d/hv_sock.conf || handle_error "Failed to create hv_sock.conf"
fi

log "Configuring PolicyKit for color management..."
cat << 'EOF' | sudo tee /etc/polkit-1/rules.d/45-allow-colord.rules > /dev/null
polkit.addRule(function(action, subject) {
    if (
        subject.isInGroup("users") &&
        (
            action.id == "org.freedesktop.color-manager.create-device" ||
            action.id == "org.freedesktop.color-manager.create-profile" ||
            action.id == "org.freedesktop.color-manager.delete-device" ||
            action.id == "org.freedesktop.color-manager.delete-profile" ||
            action.id == "org.freedesktop.color-manager.modify-device" ||
            action.id == "org.freedesktop.color-manager.modify-profile"
        )
    ) {
        return polkit.Result.YES;
    }
});
EOF

# Reload systemd and start XRDP
log "Reloading systemd and starting XRDP services..."
systemctl daemon-reload || handle_error "Failed to reload systemd"
systemctl start xrdp || handle_error "Failed to start XRDP service"

log "Hyper-V Enhanced Session configuration complete. You may now use Enhanced Session Mode in Hyper-V."