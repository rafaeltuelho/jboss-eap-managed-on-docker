#!/bin/bash

# every custom containers' startup script 
# should call this script befor start the main process.

export CONTAINER_IP_ADDR=$(ip a s | sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}')
#export CONTAINER_IP_ADDR=$(hostname -i)

# map the container's hostname to dnsmasq service
echo "$CONTAINER_IP_ADDR $HOSTNAME" > /dnsmasq.hosts/0host_$HOSTNAME

# trick to enable ping (ICMP) inside the container
echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

