# SPDX-License-Identifier: MPL-2.0

# This Kea docker image provides the following functionality:
# - running Kea DHCPv4 service
# TODO: - running Kea control agent (exposes REST API over http)
# - open source hooks

FROM alpine:3.17
LABEL org.opencontainers.image.authors="Kea Developers <kea-dev@lists.isc.org>"

# Add Kea packages from cloudsmith. Make sure the version matches that of the Alpine version.
# Also, install all the open source hooks. When updating, new instructions can
# be found at: https://cloudsmith.io/~isc/repos/kea-2-3/setup/#formats-alpine
RUN apk update && apk add curl && \
    curl -1sLf 'https://dl.cloudsmith.io/public/isc/kea-2-3/rsa.67D22B06FDC8FD58.key' > /etc/apk/keys/kea-2-3@isc-67D22B06FDC8FD58.rsa.pub && \
    curl -1sLf 'https://dl.cloudsmith.io/public/isc/kea-2-3/config.alpine.txt?distro=alpine&codename=v3.15' >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache isc-kea-dhcp4 isc-kea-ctrl-agent isc-kea-hooks

ARG TOKEN
ARG KEY
# maybe rsa key name also should be parameter
RUN if [ -n "$TOKEN" ]; then \
    cp /etc/apk/repositories /etc/apk/repositories_backup && \
    curl -1sLf "https://dl.cloudsmith.io/${TOKEN}/isc/kea-2-3-prv/rsa.3ACDF039B17886F3.key" > /etc/apk/keys/kea-2-3-prv@isc-3ACDF039B17886F3.rsa.pub &&  \
    curl -1sLf "https://dl.cloudsmith.io/${TOKEN}/isc/kea-2-3-prv/config.alpine.txt?distro=alpine&codename=v3.17" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
            isc-kea-premium-cb-cmds \
            isc-kea-premium-class-cmds \
            isc-kea-premium-ddns-tuning \
            isc-kea-premium-flex-id \
            isc-kea-premium-forensic-log \
            isc-kea-premium-host-cache \
            isc-kea-premium-host-cmds \
            isc-kea-premium-lease-query \
            isc-kea-premium-limits \
            isc-kea-premium-rbac \
            isc-kea-premium-subnet-cmds && \
    mv /etc/apk/repositories_backup /etc/apk/repositories; \
  fi


VOLUME ["/etc/kea", "/var/log"]

# 8080 ctrl agent
# 8081 ha mt
# 67 tcp blq
# 67 udp dhcp
EXPOSE 8080/udp 8081/udp 67/tcp 67/udp

RUN /usr/sbin/kea-ctrl-agent -c /etc/kea/kea-ctrl-agent.conf &
CMD ["/usr/sbin/kea-dhcp4", "-c", "/etc/kea/kea-dhcp4.conf"]
