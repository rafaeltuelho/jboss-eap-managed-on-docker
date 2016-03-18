#!/bin/sh

# call the runtime setup
/usr/bin/runtime_setup.sh

# set the agent properties in a way it don't need a static agent-configuration.xml
export RHQ_AGENT_HOME=/opt/redhat/rhq-agent
export RHQ_JAVA_HOME=$JAVA_HOME
export RHQ_AGENT_DEBUG=true
export RHQ_AGENT_ADDITIONAL_JAVA_OPTS="-Drhq.agent.configuration-setup-flag=true -Drhq.agent.server.bind-address=jon-server -Drhq.agent.wait-for-server-at-startup-msecs=600000"

# start service in background here
echo "starting RHQ Agent service..."
$RHQ_AGENT_HOME/bin/rhq-agent-wrapper.sh start

stop_container(){
        echo -e "\n\t >>> shutdown the container process...\n"
	echo -e "\t\t stoping RHQ Agent service..."
	$RHQ_AGENT_HOME/bin/rhq-agent-wrapper.sh stop
        echo "exited $0"
}

# catch the stop/kill signals from shell
trap 'echo TRAPed signal; stop_container' HUP INT QUIT KILL TERM

# call the centos-postgresql base image' startup script
run-postgresql


