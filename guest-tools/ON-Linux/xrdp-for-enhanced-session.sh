#!/bin/bash
# Enable Hyper-V Enhanced Session Mode for Debian / Ubuntu (including pre-release Ubuntu 25.10) VMs
# This script now auto-detects distro & version and adjusts GNOME session variables.
# It also handles expected apt "Release file / suite change" warnings typical of development releases.

# Exit immediately if a command exits with a non-zero status
set -e

# ----------------------
# Utility Functions
# ----------------------

# Function for error handling
handle_error() {
    echo "ERROR: ${1:-"An unknown error occurred"}" >&2
    exit 1
}

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

warn() { echo "[WARN] $1" >&2; }

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    handle_error "This script must be run with root privileges"
fi

# ----------------------
# Distro Detection
# ----------------------
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID=${ID:-unknown}
    DISTRO_VERSION_ID=${VERSION_ID:-unknown}
    DISTRO_NAME=${PRETTY_NAME:-$ID}
else
    warn "/etc/os-release not found; proceeding with generic defaults"
    DISTRO_ID=unknown
    DISTRO_VERSION_ID=unknown
    DISTRO_NAME=Unknown
fi

log "Detected distribution: ${DISTRO_NAME} (id=${DISTRO_ID}, version=${DISTRO_VERSION_ID})"

# Determine GNOME environment variables based on distro
GNOME_SESSION_MODE="GNOME"
XDG_DESKTOP_VAL="GNOME"
case "$DISTRO_ID" in
  debian)
    GNOME_SESSION_MODE="debian"
    XDG_DESKTOP_VAL="debian:GNOME"
    ;;
  ubuntu)
    # Ubuntu typically uses 'ubuntu' session mode
    GNOME_SESSION_MODE="ubuntu"
    XDG_DESKTOP_VAL="ubuntu:GNOME"
    ;;
  *)
    warn "Unrecognized distro id '$DISTRO_ID'; falling back to generic GNOME session variables. Enhanced session should still work."
    ;;
esac

# Pre-release / development release notice
if printf '%s' "$DISTRO_VERSION_ID" | grep -Eq '(alpha|beta|-rc|development)'; then
    warn "You appear to be on a development / pre-release version ($DISTRO_VERSION_ID). Proceeding with best-effort settings."
fi

# ----------------------
# Robust apt update handling (handles Release file suite change for dev / new cycles)
# ----------------------
apt_update_safe() {
    log "Updating system package lists..."
    set +e
    # Capture stderr separately (portable; avoids bash-only process substitution)
    apt-get update 2> /tmp/apt_update.err
    local rc=$?
    # Echo captured stderr so user still sees warnings/errors
    if [ -s /tmp/apt_update.err ]; then
        cat /tmp/apt_update.err >&2
    fi
    if [ $rc -ne 0 ]; then
        if grep -qi 'Release file' /tmp/apt_update.err || grep -qi 'release info' /tmp/apt_update.err; then
            warn "Apt update failed due to Release file / suite change. Retrying with --allow-releaseinfo-change options."
            apt-get update --allow-releaseinfo-change --allow-releaseinfo-change-suite 2>> /tmp/apt_update.err || handle_error "Apt update still failed after allowing release info change"
        else
            handle_error "Failed to update package information (rc=$rc)"
        fi
    fi
    set -e
}

apt_upgrade_safe() {
    log "Upgrading installed packages (this may take a while)..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y || handle_error "Failed to upgrade packages"
}

###############################################################################
# Update / Upgrade
###############################################################################
apt_update_safe
apt_upgrade_safe

if [ -f /var/run/reboot-required ]; then
    handle_error "A reboot is required in order to proceed with the install.\nPlease reboot and re-run this script to finish the install."
fi

# Install XRDP stack (xrdp + xorgxrdp for proper Xorg backend)
log "Installing XRDP stack packages..."
apt-get install -y xrdp xorgxrdp || handle_error "Failed to install XRDP packages"

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

###############################################################################
# Session Script (dynamic for Debian / Ubuntu / generic GNOME)
###############################################################################
log "Creating / updating custom XRDP session script for GNOME..."
cat > /etc/xrdp/custom.sh << EOF || handle_error "Failed to create custom.sh"
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=${GNOME_SESSION_MODE}
export XDG_CURRENT_DESKTOP=${XDG_DESKTOP_VAL}
exec /etc/xrdp/startwm.sh
EOF
chmod a+x /etc/xrdp/custom.sh || handle_error "Failed to make custom.sh executable"

# Ensure sesman uses custom script
if grep -q '^DefaultWindowManager=' /etc/xrdp/sesman.ini; then
    sed -i 's#^DefaultWindowManager=.*#DefaultWindowManager=custom#' /etc/xrdp/sesman.ini || handle_error "Failed to set DefaultWindowManager"
else
    echo 'DefaultWindowManager=custom' >> /etc/xrdp/sesman.ini || handle_error "Failed to append DefaultWindowManager"
fi

# Configure sesman.ini to use the custom session script and rename redirected drives
log "Configuring XRDP session manager..."
sed -i 's/startwm/custom/g' /etc/xrdp/sesman.ini || handle_error "Failed to update session script in sesman.ini"
sed -i 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini || handle_error "Failed to update FuseMountName in sesman.ini"

# Allow anybody to start X sessions (needed for XRDP)
log "Configuring X server permissions..."
if grep -q '^allowed_users=' /etc/X11/Xwrapper.config; then
    sed -i 's/^allowed_users=.*/allowed_users=anybody/g' /etc/X11/Xwrapper.config || handle_error "Failed to update allowed_users in Xwrapper.config"
else
    echo 'allowed_users=anybody' >> /etc/X11/Xwrapper.config || handle_error "Failed to add allowed_users to Xwrapper.config"
fi

# Ensure hv_sock gets loaded at boot & load immediately if not present
log "Configuring Hyper-V socket module..."
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
    echo "hv_sock" > /etc/modules-load.d/hv_sock.conf || handle_error "Failed to create hv_sock.conf"
fi
if ! lsmod | grep -q '^hv_sock'; then
    modprobe hv_sock || warn "Could not load hv_sock module (it may already be builtin)"
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
log "Distro: ${DISTRO_NAME} | Session Mode: ${GNOME_SESSION_MODE} | Desktop: ${XDG_DESKTOP_VAL}"
log "If the Hyper-V connection still opens in basic mode, close it and reconnect selecting 'Show Options' -> 'Enhanced Session' or verify that Enhanced Session Mode is enabled on the host."