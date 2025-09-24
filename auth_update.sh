#!/bin/sh

HAPROXY_CFG=/usr/local/etc/haproxy/haproxy.cfg
HAPROXY_CFG_TEMPLATE=${HAPROXY_CFG}.tmpl

log() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Get the token with error checking
if [ -n "$REGISTRY_ID" ]; then
   log "Using specific registry ID: $REGISTRY_ID"
   reg_url="https://${REGISTRY_ID}.dkr.ecr.${REGION}.amazonaws.com"
   log "Registry URL set to: $reg_url"
   token=$(aws ecr get-login-password --region $REGION)
   if [ -z "$token" ]; then
       log "Error: Failed to get ECR token"
       exit 1
   fi
else
   token=$(aws ecr get-login-password --region $REGION)
   if [ -z "$token" ]; then
       log "Error: Failed to get ECR token"
       exit 1
   fi
   reg_url=$(aws ecr get-authorization-token --query 'authorizationData[].proxyEndpoint' --output text)
   if [ -z "$reg_url" ]; then
       log "Error: Failed to get registry URL"
       exit 1
   fi
   log "Registry URL obtained: $reg_url"
fi

# Clean URL before generating auth string
reg_url_clean=$(echo "$reg_url" | sed 's|https://||')

# Generate auth string and verify it's not empty
auth_n=$(echo "AWS:${token}" | base64 -w 0)
if [ -z "$auth_n" ]; then
   log "Error: Failed to generate auth string"
   exit 1
fi

# Debug log before sed
log "Updating config with URL: ${reg_url_clean} and auth token length: ${#auth_n}"

# Update HAProxy config with error checking
cp ${HAPROXY_CFG_TEMPLATE} ${HAPROXY_CFG}
if ! sed -i "s|REGISTRY_URL|${reg_url_clean}|g" ${HAPROXY_CFG}; then
   log "Error: Failed to update registry URL in config"
   exit 1
fi
if ! sed -i "s|ECR_AUTH_TOKEN|${auth_n}|g" ${HAPROXY_CFG}; then
   log "Error: Failed to update auth token in config"
   exit 1
fi

# Validate config
if ! haproxy -c -f ${HAPROXY_CFG}; then
   log "Error: Invalid HAProxy configuration"
   exit 1
fi

if [ -f /var/run/haproxy.pid ]; then
    MASTER_PID=$(cat /var/run/haproxy.pid)
    if kill -0 $MASTER_PID 2>/dev/null; then
        log "Sending graceful reload signal to HAProxy master process"
        # Send SIGUSR2 for graceful reload
        kill -SIGUSR2 $MASTER_PID

        # Wait for new worker to start (optional)
        sleep 5

        # Verify HAProxy is still running
        if ! kill -0 $MASTER_PID 2>/dev/null; then
            log "Error: HAProxy master process not running after reload"
            exit 1
        fi

        log "HAProxy reload completed successfully"
    fi
fi
