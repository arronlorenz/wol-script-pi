# wol-script-pi

This repository contains a Bash script that keeps Proxmox nodes awake by sending Wake-on-LAN packets when they become unreachable. The script can run from cron or a systemd timer and logs to the system journal.

## Usage

1. Create `/etc/power-on-cluster.conf` with one `ip|mac` pair per line. Example:

```
192.168.10.53|48:21:0b:5a:45:49
192.168.10.51|88:ae:dd:04:b6:64
```

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
