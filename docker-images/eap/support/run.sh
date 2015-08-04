#!/bin/bash
set -e

# call the runtime setup
. /runtime_setup.sh

EAP_RUNTIME_MODE="${1:-standalone}"

# check the startup mode specified (defaults to standalone)
if [ "$EAP_RUNTIME_MODE" == 'standalone' ]
then
   echo -e "\n\t >>> starting JBoss EAP $EAP_VERSION in Standalone mode with full profile (HA support) <<< \n"
   echo -e "\t\t using the IP $CONTAINER_IP_ADDR "
   echo -e "\t\t startup parameters passed to container: [$@] "
   
   ADDITIONAL_PARAMS=" "
   [[ "$#" -gt 1  ]] && ADDITIONAL_PARAMS=${@:2}
   
   echo -e "\t\t JBoss startup ADDITIONAL parameters: [$ADDITIONAL_PARAMS] \n"

   # some properties to avoid JGroups issues when using cluster/ha profiles
   JAVA_OPTS="-Djboss.node.name=$HOSTNAME -Djgroups.bind_addr=$CONTAINER_IP_ADDR"
   # when using mod_cluster, change the default node name
   JAVA_OPTS="$JAVA_OPTS -Djboss.mod_cluster.jvmRoute=$HOSTNAME -DjvmRoute=$HOSTNAME"
   export JAVA_OPTS

   # bind the public interface to 0.0.0.0 due a issue with mod_cluster advertize (
   #	NOTE: I really don't know why yet, but the multicast advertize on RHEL7 Docker container only works 
   # 	      if I bind the public interface of JBoss EAP node to 0.0.0.0 addr)
   #	      Maybe I'm doing something wrong :-/
   runuser -m jboss -c \
                "$JBOSS_HOME/bin/standalone.sh -c standalone-full.xml -b 0.0.0.0 -bunsecure='0.0.0.0' -bmanagement='0.0.0.0' $ADDITIONAL_PARAMS" &

   STOP_JBOSS_CMD="$JBOSS_HOME/bin/jboss-cli.sh -c --controller=127.0.0.1:9999 --command=':shutdown()'"

elif [ "$EAP_RUNTIME_MODE" == 'domain' ]
then
   echo -e "\n\t >>> starting JBoss EAP $EAP_VERSION in Domain mode <<<"
   echo -e "\t\t using the IP $CONTAINER_IP_ADDR "
   echo -e "\t\t startup parameters passed to conatiner: [$@] "
   
   ADDITIONAL_PARAMS=" "
   [[ "$#" -gt 1  ]] && ADDITIONAL_PARAMS=${@:2}
   
   echo -e "\t\t JBoss startup ADDITIONAL parameters: [$ADDITIONAL_PARAMS] \n "

   #define the hostname used in stop command for domain mode
   JBOSS_HOST_NAME="master"
   MASTER_SERVER="master"
   MASTER_PORT=9999

   # if is a host slave sets it as DC backup
   if [[ $@ == *slave* ]]
   then
      JBOSS_HOST_NAME="$HOSTNAME"
      ADDITIONAL_PARAMS="$ADDITIONAL_PARAMS --backup"

      #test if the data base backend is up!
      MASTER_STATUS="DOWN"
      COUNTER=0
      while [ "$MASTER_STATUS" == "DOWN" -a $COUNTER -lt 6 ]
      do
         MASTER_STATUS=`(echo > /dev/tcp/$MASTER_SERVER/$MASTER_PORT) >/dev/null 2>&1 && echo "UP" || echo "DOWN"`
         echo -e "\t MASTER connection status: $MASTER_STATUS"
         echo -e "\t t_$COUNTER: [$(date +'%H:%M:%S')] waintig 10s for MASTER connetion..."
         sleep 10
         let COUNTER=COUNTER+1
      done
   fi

   # some properties to avoid JGroups issues when using cluster/ha profiles
   SERVER_OPTS="-Djboss.node.name=$HOSTNAME -Djgroups.bind_addr=$CONTAINER_IP_ADDR"
   export SERVER_OPTS

   runuser -m jboss -c \
        "$JBOSS_HOME/bin/domain.sh -b 0.0.0.0 -bunsecure='0.0.0.0' -bmanagement='0.0.0.0' $ADDITIONAL_PARAMS" &

   STOP_JBOSS_CMD="$JBOSS_HOME/bin/jboss-cli.sh --connect --controller=127.0.0.1:9999 command='/host=$JBOSS_HOST_NAME:shutdown'"

fi

echo "starting RHQ Agent service..."
$RHQ_AGENT_HOME/bin/rhq-agent-wrapper.sh start

stop_container(){
        echo -e "\n\t >>> shutdown the container process...\n"
	echo -e "\t\tstoping RHQ Agent service..."
	$RHQ_AGENT_HOME/bin/rhq-agent-wrapper.sh stop
	
	echo -e "\t\tstoping JBoss service..."
	echo -e "\t\t [$STOP_JBOSS_CMD]"
	runuser -m jboss -c "$STOP_JBOSS_CMD"
        
        echo "exited $0"
}

# catch the stop/kill signals from shell
trap 'echo TRAPed signal; stop_container' HUP INT QUIT KILL TERM

wait %1

