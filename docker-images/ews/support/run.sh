#!/bin/sh
# from Docker official reference manual
# Note: I've written this using sh so it works in the busybox container too

# call the runtime setup
. /runtime_setup.sh

stop_container(){
        echo -e "\n\t >>> shutdown the container process...\n"
	# stop service and clean up here
	echo -e "\t\tstopping Httpd servicei..."
	$HTTPD_HOME/sbin/apachectl stop
	
	echo -e "\t\tstoping RHQ Agent service..."
	$RHQ_AGENT_HOME/bin/rhq-agent-wrapper.sh stop 
        echo "exited $0"
}

# catch the stop/kill signals from shell
trap 'echo TRAPed signal; stop_container' HUP INT QUIT KILL TERM

# start service in background here
echo -e "\n >>> starting RHQ Agent service..."
$RHQ_AGENT_HOME/bin/rhq-agent-wrapper.sh start 

echo -e "\n >>> starting Httpd service..."
#$HTTPD_HOME/sbin/apachectl start
$HTTPD_HOME/sbin/apachectl -D FOREGROUND &
wait %1

#echo -e "\n\t >>> Container's startup process ($0) runing in foreground . HIT enter to STOP!!!"
#read
