#!/bin/sh

# Do initial update
export INITIAL_RUN=true
/auth_update.sh

# Start auth renewal in background
(while true; do
    sleep 6h
    unset INITIAL_RUN
    /auth_update.sh
done) &

# Start HAProxy
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg
