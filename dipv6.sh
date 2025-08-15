#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [--revert]"
    echo "  --revert    Re-enable IPv6 (restore original settings)"
    echo "  (no args)   Disable IPv6"
}

# Function to revert IPv6 settings
revert_ipv6() {
    echo "Re-enabling IPv6..."

    # Find the most recent backup
    BACKUP_FILE=$(ls -t /etc/sysctl.conf.bak-* 2>/dev/null | head -n1)

    if [[ -n "$BACKUP_FILE" ]]; then
        echo "Found backup: $BACKUP_FILE"
        echo "Restoring original sysctl.conf from backup..."
        cp "$BACKUP_FILE" /etc/sysctl.conf
    else
        echo "No backup found. Removing IPv6 disable settings manually..."
        # Remove IPv6 disable lines from sysctl.conf
        sed -i '/# Disable IPv6/d' /etc/sysctl.conf
        sed -i '/net.ipv6.conf.all.disable_ipv6=1/d' /etc/sysctl.conf
        sed -i '/net.ipv6.conf.default.disable_ipv6=1/d' /etc/sysctl.conf
        sed -i '/net.ipv6.conf.all.accept_redirects=0/d' /etc/sysctl.conf
    fi

    # Temporarily enable IPv6 at the kernel level
    echo "Enabling IPv6 for all interfaces..."
    sysctl -w net.ipv6.conf.all.disable_ipv6=0
    sysctl -w net.ipv6.conf.default.disable_ipv6=0
    sysctl -w net.ipv6.conf.all.accept_redirects=1

    # Apply sysctl settings
    sysctl -p

    # Restart networking to fully restore IPv6
    echo "Restarting networking service..."
    if systemctl is-active --quiet NetworkManager; then
        systemctl restart NetworkManager
    elif systemctl is-active --quiet networking; then
        systemctl restart networking
    else
        echo "Please restart networking manually or reboot the system."
    fi

    # Check IPv6 status after changes
    echo "Checking IPv6 status..."
    sleep 2
    ip a | grep inet6 && echo "IPv6 has been successfully re-enabled!" || echo "IPv6 not yet visible. You may need to reboot."

    echo "IPv6 re-enable complete. Reboot recommended: sudo reboot"
    exit 0
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)."
   exit 1
fi

# Check for arguments
if [[ "$1" == "--revert" ]]; then
    revert_ipv6
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
elif [[ $# -gt 0 ]]; then
    echo "Unknown argument: $1"
    usage
    exit 1
fi

# Create a backup of the current sysctl configuration
echo "Creating a backup of /etc/sysctl.conf..."
cp /etc/sysctl.conf /etc/sysctl.conf.bak-$(date +%F_%H-%M-%S)

# Display current IPv6 addresses
echo "Current IPv6 addresses:"
ip a | grep inet6

# Temporarily disable IPv6 at the kernel level
echo "Disabling IPv6 for all interfaces..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.all.accept_redirects=0

# Permanently disable IPv6 via /etc/sysctl.conf
echo "Adding settings to /etc/sysctl.conf for permanent IPv6 disable..."
cat >> /etc/sysctl.conf <<EOL

# Disable IPv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.all.accept_redirects=0
EOL

# Apply sysctl settings
sysctl -p

# Check IPv6 status after changes
echo "Checking IPv6 status..."
ip a | grep inet6 || echo "No IPv6 addresses found."

# Check IPv4 availability
echo "Checking IPv4..."
ip a | grep inet | grep -v inet6 || echo "No IPv4 addresses found. Ensure IPv4 is configured to avoid losing network access."

# Warning
echo "IPv6 has been disabled. Reboot the server to verify: sudo reboot"
echo "WARNING: Ensure IPv4 is configured and working, or you may lose server access!"