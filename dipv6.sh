#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)."
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