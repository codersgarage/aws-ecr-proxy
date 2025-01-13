#!/bin/sh
# entrypoint.sh

# Do initial update
/auth_update.sh

# Start HAProxy in master-worker mode
haproxy -W -f /usr/local/etc/haproxy/haproxy.cfg &
MASTER_PID=$!

# Store master PID
echo $MASTER_PID > /var/run/haproxy.pid

# Start auth renewal in background
(while true; do
    sleep 6h
    # If auth update fails, exit the container
    /auth_update.sh || exit 1
done) &

# Wait for master process
wait $MASTER_PID
