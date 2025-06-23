# wol-script-pi

This repository contains a small Bash script to wake several servers using Wake-on-LAN. The script checks whether each host is reachable and sends magic packets when needed.

## Usage

1. Edit the `HOSTS` and `MACS` arrays in `power-on-server.sh` so that each MAC corresponds to the matching host.
2. Ensure the `wakeonlan` and `etherwake` utilities are installed on the system running the script.    
    The script checks for these commands and aborts if they are missing. Array lengths are also verified.
3. Make the script executable and run it manually:

```bash
chmod +x power-on-server.sh
./power-on-server.sh
```

For unattended operation, schedule the script via cron:

```
@hourly /usr/bin/bash /home/pi/power-on-server.sh >>/home/pi/power-on-server.log 2>&1
```

## Dependencies

- bash
- wakeonlan
- etherwake

The script was adapted from content published by technotim.
