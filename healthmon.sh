#!/usr/bin/env bash
# healthmon.sh - CPU, memory, disk, HTTP checks. Exit: 0=OK 1=WARN 2=CRIT
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPU_WARN=70; CPU_CRIT=90; MEM_WARN=75; MEM_CRIT=90; DISK_WARN=80; DISK_CRIT=90
DISK_PATH=/; HTTP_URL="http://127.0.0.1:8080/"; HTTP_TIMEOUT=5; HTTP_WARN_MS=1500
LOG_DIR="${HEALTHMON_LOG_DIR:-$DIR/logs}"
# shellcheck disable=SC1090
[ -f "${HEALTHMON_CONF:-$DIR/healthmon.conf}" ] && . "${HEALTHMON_CONF:-$DIR/healthmon.conf}"
mkdir -p "$LOG_DIR"

cpu_usage() {
  local _ u n s i w q sq st t1 i1 t2 i2
  read -r _ u n s i w q sq st _ < /proc/stat; t1=$((u+n+s+i+w+q+sq+st)); i1=$((i+w))
  sleep 1
  read -r _ u n s i w q sq st _ < /proc/stat; t2=$((u+n+s+i+w+q+sq+st)); i2=$((i+w))
  local dt=$((t2-t1)); [ "$dt" -le 0 ] && { echo 0; return; }
  echo $(( 100 * (dt - (i2-i1)) / dt ))
}
mem_usage() { awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%d",100*(t-a)/t}' /proc/meminfo; }
disk_usage() { df -P "$DISK_PATH" | awk 'NR==2{gsub("%","",$5);print $5}'; }
level() { [ "$1" -ge "$3" ] && echo 2 || { [ "$1" -ge "$2" ] && echo 1 || echo 0; }; }
max() { [ "$1" -gt "$2" ] && echo "$1" || echo "$2"; }

cpu=$(cpu_usage); mem=$(mem_usage); disk=$(disk_usage)
read -r code secs < <(curl -o /dev/null -s -L -w '%{http_code} %{time_total}' --max-time "$HTTP_TIMEOUT" "$HTTP_URL" 2>/dev/null || echo "000 0")
ms=$(awk -v s="${secs:-0}" 'BEGIN{printf "%d", s*1000}')

lc=$(level "$cpu" $CPU_WARN $CPU_CRIT); lm=$(level "$mem" $MEM_WARN $MEM_CRIT); ld=$(level "$disk" $DISK_WARN $DISK_CRIT)
if [[ "$code" =~ ^[23] ]]; then lh=0; [ "$ms" -ge "$HTTP_WARN_MS" ] && lh=1; else lh=2; fi
worst=$(max "$(max "$lc" "$lm")" "$(max "$ld" "$lh")")
names=(OK WARN CRIT)

ts=$(date '+%Y-%m-%d %H:%M:%S')
printf '[%s] [%s] cpu=%s%% mem=%s%% disk=%s%% http=%s (%sms)\n' "$ts" "${names[$worst]}" "$cpu" "$mem" "$disk" "$code" "$ms" | tee -a "$LOG_DIR/healthmon.log"

printf '{"t":"%s","cpu":%s,"mem":%s,"disk":%s,"code":"%s","ms":%s,"lv":{"cpu":%s,"mem":%s,"disk":%s,"http":%s},"level":%s,"th":{"cpu":[%s,%s],"mem":[%s,%s],"disk":[%s,%s],"to":%s}}\n' \
  "$ts" "$cpu" "$mem" "$disk" "$code" "$ms" "$lc" "$lm" "$ld" "$lh" "$worst" \
  "$CPU_WARN" "$CPU_CRIT" "$MEM_WARN" "$MEM_CRIT" "$DISK_WARN" "$DISK_CRIT" "$HTTP_TIMEOUT" >> "$LOG_DIR/history.jsonl"
tail -n 500 "$LOG_DIR/history.jsonl" > "$LOG_DIR/.h" && mv "$LOG_DIR/.h" "$LOG_DIR/history.jsonl"
exit "$worst"
