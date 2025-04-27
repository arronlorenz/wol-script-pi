#!/usr/bin/env bash
set -euo pipefail
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Runs hourly via cron: crontab -e
# @hourly /usr/bin/bash /home/pi/power-on-server.sh >>/home/pi/power-on-server.log 2>&1

HOSTS=(192.168.10.53 192.168.10.51 192.168.10.50 192.168.0.76)
MACS=(48:21:0b:5a:45:49 88:ae:dd:04:b6:64 88:ae:dd:07:f3:15 dc:a6:32:7d:55:29)
PING='/bin/ping -q -c1 -W1'     # 1-second timeout

is_up() { $PING "$1" &>/dev/null; }

wake_up() {
    local mac=$1 host=$2
    for _ in {1..5}; do
        /usr/bin/wakeonlan "$mac"
        /usr/sbin/etherwake  "$mac"
        sleep 10
        is_up "$host" && return 0
    done
    return 1
}

check_network() {
    if ! is_up 1.1.1.1 && ! is_up 8.8.8.8; then
        echo "$(date)  Internet unreachable – restarting network"
        systemctl restart systemd-networkd   # adjust for your setup
        sleep 10
    fi
}

down=0
for i in "${!HOSTS[@]}"; do
    host=${HOSTS[$i]}
    if ! is_up "$host"; then
        echo "$(date)  $host is down"
        check_network
        wake_up "${MACS[$i]}" "$host" || ((down++))
    else
        echo "$(date)  $host is up"
    fi
done

if (( down == ${#HOSTS[@]} )); then        # reboot only if *all* are still down
    echo "$(date)  All hosts down – rebooting Pi"
    /sbin/shutdown -r now
else
    echo "$(date)  Reboot skipped – at least one host is up"
fi
