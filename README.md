# wol-script-pi

This repository contains a Bash script that keeps Proxmox nodes awake by sending Wake-on-LAN packets when they become unreachable. The script can run from cron or a systemd timer and logs to the system journal.

## Usage

1. Edit the `HOSTS` and `MACS` arrays at the top of `power-on-server.sh` with
   the IP and MAC address pairs for your nodes.

2. Ensure the following utilities are installed: `wakeonlan`, `etherwake`, `flock`, and `logger` (usually part of util-linux). The script checks for these commands.
3. Make the script executable and run it manually:

```bash
chmod +x power-on-server.sh
./power-on-server.sh
```

For unattended operation schedule it via cron or a systemd timer. A simple cron entry:

```
@hourly /usr/bin/bash /path/to/power-on-server.sh
```

## Dependencies

- bash
- wakeonlan
- etherwake
- util-linux (for `flock` and `logger`)

The script was adapted from content published by technotim.
