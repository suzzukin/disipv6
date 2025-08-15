# disipv6

A simple script to disable IPv6 on Linux systems.

## What it does

This script:
- Creates a backup of your current sysctl configuration
- Displays current IPv6 addresses
- Disables IPv6 temporarily and permanently
- Adds permanent IPv6 disable settings to `/etc/sysctl.conf`
- Provides warnings about ensuring IPv4 connectivity

## Usage with curl

### Disable IPv6

```bash
curl -sSL https://raw.githubusercontent.com/suzzukin/disipv6/master/dipv6.sh | sudo bash
```

### Re-enable IPv6 (Revert)

```bash
curl -sSL https://raw.githubusercontent.com/suzzukin/disipv6/master/dipv6.sh | sudo bash -s -- --revert
```

### Download and run locally

```bash
curl -O https://raw.githubusercontent.com/suzzukin/disipv6/master/dipv6.sh
chmod +x dipv6.sh
sudo ./dipv6.sh          # to disable IPv6
sudo ./dipv6.sh --revert # to re-enable IPv6
```

## Requirements

- Linux system with systemd
- Root privileges (script will prompt for sudo)
- Ensure IPv4 connectivity is working before running

## Warning

⚠️ **Important**: Make sure IPv4 is properly configured before disabling IPv6, or you may lose network access to your server!
