FROM haproxy:alpine3.21

USER root

RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    && pip3 install --upgrade pip --break-system-packages \
    && pip3 install --no-cache-dir --break-system-packages \
        awscli \
    && rm -rf /var/cache/apk/*

COPY haproxy/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY entrypoint.sh /entrypoint.sh
COPY auth_update.sh /auth_update.sh

RUN chmod +x /entrypoint.sh /auth_update.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
