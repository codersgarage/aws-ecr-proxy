#!/bin/bash

while true; do
    sleep "${RENEW_TOKEN:-6h}"
    /auth_update.sh
    # Reload HAProxy with zero downtime
    haproxy -f /usr/local/etc/haproxy/haproxy.cfg -sf $(cat /var/run/haproxy.pid)
done
