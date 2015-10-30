#!/bin/bash

echo -e "\n\t >>> starting dnsmaq service for local Docker containers <<< \n"

stop_container(){
        echo -e "\n\t >>> shutdown the container process...\n"
        /usr/sbin/incrond -k
        pkill dnsmasq

        echo "exited $0"
}

# catch the stop/kill signals from shell
trap 'echo TRAPed signal; stop_container' HUP INT QUIT KILL TERM

# start services daemons
/usr/sbin/incrond
/usr/sbin/dnsmasq -d
pkill -HUP dnsmasq
