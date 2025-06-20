#!/bin/bash
# Check Hyper-V Enhanced Session Mode requirements on Linux guest

echo "Checking Hyper-V Enhanced Session Mode requirements..."

# 1. Check if running inside Hyper-V
if grep -q 'Microsoft Hv' /proc/cpuinfo; then
    echo "✔ Running inside a Hyper-V virtual machine."
else
    echo "✖ Not running inside a Hyper-V VM."
fi

# 2. Check for hv_vmbus kernel module
if lsmod | grep -q hv_vmbus; then
    echo "✔ hv_vmbus module loaded."
else
    echo "✖ hv_vmbus module NOT loaded."
fi

# 3. Check for XRDP service (for enhanced session)
if systemctl is-active --quiet xrdp; then
    echo "✔ xrdp service is running."
else
    echo "✖ xrdp service is NOT running."
fi

# 4. Check for xorgxrdp driver (for graphical session)
if dpkg -l | grep -q xorgxrdp || rpm -qa | grep -q xorgxrdp; then
    echo "✔ xorgxrdp package is installed."
else
    echo "✖ xorgxrdp package is NOT installed."
fi

# 5. Check for hv_sock support (for clipboard, drive redirection, etc.)
if lsmod | grep -q hv_sock; then
    echo "✔ hv_sock module loaded."
else
    echo "✖ hv_sock module NOT loaded."
fi

echo "Check complete."