#!/bin/bash
# Enable Hyper-V Enhanced Session Mode for this Debian 12 VM

set -e

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# Update system
apt update && apt upgrade -y
if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

# Install XRDP
echo "Prepping your system for enhanced session mode."
apt install -y xrdp
systemctl stop xrdp xrdp-sesman

# Backup config files
cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
cp /etc/xrdp/sesman.ini /etc/xrdp/sesman.ini.bak
cp /etc/X11/Xwrapper.config /etc/X11/Xwrapper.config.bak

# Update xrdp.ini for Hyper-V Enhanced Session
sed -i 's/port=3389/port=vsock:\/\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# Ensure vmconnect=true is set (uncomment or append if missing)
if grep -q '^#vmconnect=true' /etc/xrdp/xrdp.ini; then
    sed -i 's/^#vmconnect=true/vmconnect=true/' /etc/xrdp/xrdp.ini
elif ! grep -q '^vmconnect=true' /etc/xrdp/xrdp.ini; then
    echo 'vmconnect=true' >> /etc/xrdp/xrdp.ini
fi
sed -i 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sed -i 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# Create custom session script for GNOME
if [ ! -e /etc/xrdp/startdebian.sh ]; then
cat > /etc/xrdp/startdebian.sh << 'EOF'
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=debian
export XDG_CURRENT_DESKTOP=debian:GNOME
exec /etc/xrdp/startwm.sh
EOF
sed -i '/^DefaultWindowManager=/s/startwm/startdebian/' /etc/xrdp/sesman.ini
chmod a+x /etc/xrdp/startdebian.sh
fi

# Configure sesman.ini to use the custom session script and rename redirected drives
sed -i 's/startwm/startdebian/g' /etc/xrdp/sesman.ini
sed -i 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Allow anybody to start X sessions (needed for XRDP)
if grep -q '^allowed_users=' /etc/X11/Xwrapper.config; then
    sed -i 's/^allowed_users=.*/allowed_users=anybody/g' /etc/X11/Xwrapper.config
else
    echo 'allowed_users=anybody' >> /etc/X11/Xwrapper.config
fi

# Ensure hv_sock gets loaded at boot
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
    echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla << 'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# Reload systemd and start XRDP
systemctl daemon-reload
systemctl start xrdp

echo "Hyper-V Enhanced Session configuration complete. You may now use Enhanced Session Mode in Hyper-V."