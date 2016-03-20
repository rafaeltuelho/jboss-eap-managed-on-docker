#!/bin/sh

DB_SERVER=jon-postgres
DB_PORT=5432
RHQ_SERVER_HOME=$SOFTWARE_INSTALL_DIR/jon-server-$JON_VERSION

# call the runtime setup
. /runtime_setup.sh

# test if the rhq-server is completely installed
if [[ ! -f "$RHQ_SERVER_HOME/logs/rhq-installer.log"  ]] ||
   [[ ! -d "$RHQ_SERVER_HOME/jbossas/standalone/data" ]] ||
   [[ ! -d "$RHQ_SERVER_HOME/jbossas/standalone/tmp"  ]];
then

	#test if the data base backend is up!
	DB_STATUS="DOWN"
	COUNTER=0
        while [ "$DB_STATUS" == "DOWN" -a $COUNTER -lt 6 ]
        do
	   DB_STATUS=`(echo > /dev/tcp/$DB_SERVER/$DB_PORT) >/dev/null 2>&1 && echo "UP" || echo "DOWN"`
           echo -e "\t DB connection status: $DB_STATUS"
           echo -e "\t t_$COUNTER: [$(date +'%H:%M:%S')]  waintig 5s for DB connetion..."
	   sleep 10
	   let COUNTER=COUNTER+1
	done

	if [ ! -z "$DB_STATUS" -a "$DB_STATUS" == "UP"  ]
	then
		echo -e "\n\t >>> Install RHQ/JON Server <<< \n"
		${RHQ_SERVER_HOME}/bin/rhqctl install --storage --start
		#wait %1
		${RHQ_SERVER_HOME}/bin/rhqctl install --server --start
		#wait %1
		${RHQ_SERVER_HOME}/bin/rhqctl install --agent --start
		#wait %1

                sleep 15

		${RHQ_SERVER_HOME}/bin/rhqctl status
                sleep 5
		${RHQ_SERVER_HOME}/bin/rhqctl stop

		echo -e "\n\t >>> Apply Patches/Updates to RHQ/JON Server <<< \n"
		/applyPatch.sh &
		wait %1
		
		# if there is a new init script (after the patch)
		[[ -f "$RHQ_SERVER_HOME/bin/rhqctl.new"  ]] && \
		mv $RHQ_SERVER_HOME/bin/rhqctl.new $RHQ_SERVER_HOME/bin/rhqctl

		chown -Rf jboss.jboss $SOFTWARE_INSTALL_DIR/
	else
		echo -e "\n\t *** There is no Data Base running/listening on $DB_SERVER:$DB_PORT *** \n"
		echo -e "\t\t ---> ABORTING INSTALLATION!!! "
		exit 1
	fi
fi

stop_container(){
        echo -e "\n\t >>> shutdown the container process...\n"
        echo -e "\t\t Stop RHQ/JON Services (server, storage and agent)..."
	runuser -m jboss -c "${RHQ_SERVER_HOME}/bin/rhqctl stop"
        echo "exited $0"
        exit 0
}

# catch the stop/kill signals from shell
trap 'echo TRAPed signal; stop_container' HUP INT QUIT KILL TERM

echo -e "\n\t >>> Start RHQ/JON Services (server, storage and agent)... <<< \n"
runuser -m jboss -c "${RHQ_SERVER_HOME}/bin/rhqctl start"

tail -100f ${RHQ_SERVER_HOME}/logs/server.log

#echo -e "\n\t >>> Container's startup process ($0) runing in foreground . HIT enter to STOP!!!"
#read
