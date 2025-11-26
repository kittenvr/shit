#!/usr/bin/env bash
# entrypoint.sh

# Start MQTT listener in background
python3 /app/mqtt_listener.py &

# Run proxy finder every 15 minutes
while true; do
    echo "[*] Running proxy finder at $(date)"
    bash /app/auto_find_best_proxies.sh
    echo "[*] Sleeping 15 minutes..."
    sleep 900
done
