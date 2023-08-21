# SPDX-License-Identifier: MPL-2.0

# This Kea docker image provides the following functionality:
# - running Kea DHCPv4 service
# - running Kea control agent (exposes REST API over http)
# - open source hooks
# - possible to build with premium hooks

# build docker build --build-arg VERSION=2.3.8-r20230530063557 - < docker/kea-dhcp4.Dockerfile -t kea-2.3.8
#   to add premium hooks --build-arg TOKEN=<TOKEN> --build-arg PREMIUM=ENTERPRISE
#  sudo docker run --volume=<path to kea-docker repo>/config/kea/kea-dhcp4.conf:/etc/kea/kea-dhcp4.conf  --volume=<path to kea-docker repo>/config/kea/kea-ctrl-agent-4.conf:/etc/kea/kea-ctrl-agent.conf --volume=<path to kea-docker repo>/config/supervisor/supervisord.conf:/etc/supervisor/supervisord.conf --volume=<path to kea-docker repo>/config/supervisor/kea-dhcp4.conf:/etc/supervisor/conf.d/kea-dhcp4.conf --volume=<path to kea-docker repo>/config/supervisor/kea-agent.conf:/etc/supervisor/conf.d/kea-agent.conf --network=host  kea-2.3.8

FROM alpine:3.17
LABEL org.opencontainers.image.authors="Kea Developers <kea-dev@lists.isc.org>"

# Add Kea packages from cloudsmith. Make sure the version matches that of the Alpine version.
# Also, install all the open source hooks. When updating, new instructions can
# be found at: https://cloudsmith.io/~isc/repos/kea-2-3/setup/#formats-alpine
ARG VERSION
RUN cp /etc/apk/repositories /etc/apk/repositories_backup
RUN apk update && apk add curl && \
    curl -1sLf 'https://dl.cloudsmith.io/public/isc/kea-2-3/rsa.67D22B06FDC8FD58.key' > /etc/apk/keys/kea-2-3@isc-67D22B06FDC8FD58.rsa.pub && \
    curl -1sLf 'https://dl.cloudsmith.io/public/isc/kea-2-3/config.alpine.txt?distro=alpine&codename=v3.17' >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache isc-kea-dhcp4=${VERSION} isc-kea-ctrl-agent=${VERSION} isc-kea-hooks=${VERSION} supervisor
    # apk add --no-cache isc-kea-dhcp4 isc-kea-ctrl-agent isc-kea-hooks

ARG TOKEN
ARG PREMIUM

RUN if [ -n "$TOKEN" ]; then \
    curl -1sLf "https://dl.cloudsmith.io/${TOKEN}/isc/kea-2-3-prv/rsa.3ACDF039B17886F3.key" > /etc/apk/keys/kea-2-3-prv@isc-3ACDF039B17886F3.rsa.pub &&  \
    curl -1sLf "https://dl.cloudsmith.io/${TOKEN}/isc/kea-2-3-prv/config.alpine.txt?distro=alpine&codename=v3.17" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
        isc-kea-premium-ddns-tuning=${VERSION} \
        isc-kea-premium-flex-id=${VERSION} \
        isc-kea-premium-forensic-log=${VERSION} \
        isc-kea-premium-host-cmds=${VERSION}; \
    fi

# build argument PREMIUM will define which pkgs to install but real access to pkgs are defined by individual TOKEN
# build will fail if someone will use --build-arg PREMIUM=ENTERPRISE and TOKEN with access just to premium pkgs.
RUN if [ -n "$TOKEN" ] && [ "$PREMIUM" == "SUBSCRIBERS" ]; then \
    apk add --no-cache \
        isc-kea-premium-cb-cmds=${VERSION} \
        isc-kea-premium-class-cmds=${VERSION} \
        isc-kea-premium-host-cache=${VERSION} \            
        isc-kea-premium-lease-query=${VERSION} \
        isc-kea-premium-limits=${VERSION} \
        isc-kea-premium-subnet-cmds=${VERSION}; \
    fi

RUN if [ -n "$TOKEN" ] && [ "$PREMIUM" == "ENTERPRISE" ]; then \
    apk add --no-cache \
        isc-kea-premium-cb-cmds=${VERSION} \
        isc-kea-premium-class-cmds=${VERSION} \
        isc-kea-premium-host-cache=${VERSION} \            
        isc-kea-premium-lease-query=${VERSION} \
        isc-kea-premium-limits=${VERSION} \
        isc-kea-premium-subnet-cmds=${VERSION} \
        isc-kea-premium-rbac=${VERSION}; \
    fi

RUN mv /etc/apk/repositories_backup /etc/apk/repositories;
RUN mkdir -p /var/log/supervisor
VOLUME ["/etc/kea", "/etc/supervisor/conf.d/"]

# 9000-9010/tcp ctrl agent, if multiple dockers are used ports have to be different between them
# 8081 ha mt
# 67 tcp blq
# 67 udp dhcp
EXPOSE 8081/udp 9000-9010/tcp 90/tcp 67/tcp 67/udp

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
HEALTHCHECK CMD [ "supervisorctl", "status" ]