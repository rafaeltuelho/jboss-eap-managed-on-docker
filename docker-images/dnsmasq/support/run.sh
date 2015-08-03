#!/bin/bash

echo -e "\n\t >>> starting dnsmaq service for local Docker containers <<< \n"

# start services daemons
/usr/sbin/incrond
/usr/sbin/dnsmasq -d
