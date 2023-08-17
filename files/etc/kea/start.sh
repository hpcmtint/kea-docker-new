#!/bin/sh
ifconfig eth0

/usr/sbin/kea-ctrl-agent -c /etc/kea/kea-ctrl-agent.conf &
/usr/sbin/kea-dhcp4 -c /etc/kea/kea-dhcp4.conf &

wait -n

exit $?