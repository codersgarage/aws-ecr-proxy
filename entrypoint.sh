#!/bin/sh

# Do initial update
/auth_update.sh

# Start HAProxy in master-worker mode
haproxy -W -f /usr/local/etc/haproxy/haproxy.cfg &
MASTER_PID=$!

# Store master PID
echo $MASTER_PID > /var/run/haproxy.pid

# Monitor HAProxy master process
monitor_haproxy() {
    while true; do
        if ! kill -0 $MASTER_PID 2>/dev/null; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] HAProxy master process died, exiting container"
            exit 1
        fi
        sleep 30
    done
}

# Start monitoring in background
monitor_haproxy &

# Start auth renewal in background
(while true; do
    sleep ${RENEW_INTERVAL:-6h}
    # If auth update fails, log and continue trying
    if ! /auth_update.sh; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auth update failed, will retry in 5 minutes"
        sleep 300
        continue
    fi
done) &

# Wait for master process
wait $MASTER_PID
