#!/bin/sh

HAPROXY_CFG=/usr/local/etc/haproxy/haproxy.cfg

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Get the token the same way as the original script
if [ -n "$REGISTRY_ID" ]; then
    log "Using specific registry ID: $REGISTRY_ID"
    reg_url="https://${REGISTRY_ID}.dkr.ecr.${REGION}.amazonaws.com"
    log "Registry URL set to: $reg_url"
    token=$(aws ecr get-login-password --region $REGION)
else
    token=$(aws ecr get-login-password --region $REGION)
    reg_url=$(aws ecr get-authorization-token --query 'authorizationData[].proxyEndpoint' --output text)
    log "Registry URL obtained: $reg_url"
fi

# Generate auth string
auth_n=$(echo "AWS:${token}" | base64 -w 0)

# Update HAProxy config
reg_url_clean=$(echo "$reg_url" | sed 's|https://||')
sed -i "s|REGISTRY_URL|${reg_url_clean}|g" ${HAPROXY_CFG}
sed -i "s|ECR_AUTH_TOKEN|${auth_n}|g" ${HAPROXY_CFG}

# Reload HAProxy if it's running
if [ -f /var/run/haproxy.pid ]; then
    haproxy -f ${HAPROXY_CFG} -sf $(cat /var/run/haproxy.pid)
fi
