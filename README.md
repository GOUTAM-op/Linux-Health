# Linux Health Monitor
Bash utility tracking CPU, memory, disk and HTTP availability, with timestamped logs,
threshold-based exit codes (0 OK, 1 WARN, 2 CRIT), cron scheduling and a live dashboard.

    chmod +x *.sh serve.py
    ./healthmon.sh            # one-off check (edit healthmon.conf for thresholds / URL)
    ./install_cron.sh 5       # run every 5 min  (./install_cron.sh --remove to uninstall)
    ./serve.py                # dashboard at http://127.0.0.1:8080

Logs: `logs/healthmon.log` (human) and `logs/history.jsonl` (dashboard feed).
Use in scripts: `./healthmon.sh || alert.sh`.
