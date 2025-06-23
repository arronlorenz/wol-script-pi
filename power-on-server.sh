#!/usr/bin/env bash
# power-on-cluster.sh – keep Proxmox nodes awake from a Pi Zero 2 W
#   • Runs safely from systemd-timer *or* cron
#   • Uses flock to prevent concurrent runs
#   • Uses built-in host ↔︎ MAC mappings
#   • Logs to journald via ‘logger’ for easy filtering
#   • Reboots the Pi only when *all* targets remain unreachable after N tries
#   • Shell-checked and set-euxo pipefail for robustness

set -Eeuo pipefail
shopt -s inherit_errexit         # propagate ‘set -e’ into subshells (bash 5.0+)
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ────────────────────────────────────────────────────────────────────────────
# sanity-check utilities we depend on
require_commands() {
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null; then
            echo "$cmd utility not found" >&2
            exit 1
        fi
    done
}

verify_arrays() {
    if [[ ${#HOSTS[@]} -ne ${#MACS[@]} ]]; then
        echo "HOSTS and MACS arrays must be the same length" >&2
        exit 1
    fi
}

###
# HOST ↔ MAC mappings
# Define the IP and MAC pairs directly in the script.
# Example values are shown below – adjust for your environment.
###
HOSTS=(
    192.168.10.53
    192.168.10.51
)
MACS=(
    48:21:0b:5a:45:49
    88:ae:dd:04:b6:64
)
verify_arrays
require_commands wakeonlan etherwake flock logger systemctl

LOCK_FD=200
exec {LOCK_FD}>/run/power-on-cluster.lock
flock -n "$LOCK_FD" || {
    logger -t power-on-cluster "Previous run still active – aborting"
    exit 0
}

PING='/bin/ping -q -c1 -W1'     # 1 s timeout
MAX_TRIES=5
SLEEP_BETWEEN=10                # seconds between WoL bursts

is_up() { $PING "$1" &>/dev/null; }

wake_up() {
    local mac=$1 host=$2
    for ((i=1; i<=MAX_TRIES; i++)); do
        wakeonlan "$mac" || true   # ignore exit codes – some NICs answer only to one tool
        etherwake "$mac"   || true
        sleep "$SLEEP_BETWEEN"
        is_up "$host" && return 0
    done
    return 1
}

check_network() {
    if ! is_up 1.1.1.1 && ! is_up 8.8.8.8; then
        logger -t power-on-cluster "Internet unreachable – restarting network stack"
        systemctl restart systemd-networkd || logger -t power-on-cluster "network restart failed"
        sleep 10
    fi
}

down=0
for i in "${!HOSTS[@]}"; do
    host=${HOSTS[$i]}
    if ! is_up "$host"; then
        logger -t power-on-cluster "$host is down – attempting WoL"
        check_network
        wake_up "${MACS[$i]}" "$host" || ((down++))
    else
        logger -t power-on-cluster "$host is up"
    fi
done

if (( down == ${#HOSTS[@]} )); then
    logger -t power-on-cluster "All hosts remain unreachable – rebooting Pi"
    systemctl reboot
else
    logger -t power-on-cluster "At least one host reachable – no reboot needed"
fi
