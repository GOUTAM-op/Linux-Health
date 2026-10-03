#!/usr/bin/env bash
# Usage: ./install_cron.sh [minutes=5] | ./install_cron.sh --remove
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; TAG="# healthmon"
cur=$(crontab -l 2>/dev/null | grep -v "$TAG")
if [ "${1:-}" = "--remove" ]; then echo "$cur" | crontab - && echo "Cron job removed."; exit 0; fi
m=${1:-5}; [[ "$m" =~ ^[0-9]+$ ]] && [ "$m" -ge 1 ] && [ "$m" -le 59 ] || { echo "minutes must be 1-59"; exit 1; }
printf '%s\n*/%s * * * * %s/healthmon.sh >/dev/null 2>&1 %s\n' "$cur" "$m" "$DIR" "$TAG" | sed '/^$/d' | crontab -
echo "Installed: runs every $m min. Verify with: crontab -l"
