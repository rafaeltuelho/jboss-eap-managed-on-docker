#Containers

 * dnsmasq
 * jon-postgres
 * jon-server
  * http://jon-server:7080/coregui
 * apache
  * http://apache/
  * http://apache:6666/mod_cluster_manager (open using Firefox!!!)
 * master
  * http://master:9990/console
 * eap-slave1
  * http://eap-slave1:8230/
 * eap-slave2
  * http://eap-slave2:8230/

 * to access Container's terminal use

 ```
 docker exec -i -t jbosseapmanagedondocker_dnsmasq_1     /bin/bash
 docker exec -i -t jbosseapmanagedondocker_eapmaster_1   /bin/bash
 docker exec -i -t jbosseapmanagedondocker_eapslave1_1   /bin/bash
 docker exec -i -t jbosseapmanagedondocker_eapslave2_1   /bin/bash
 docker exec -i -t jbosseapmanagedondocker_ewshttpd_1    /bin/bash
 docker exec -i -t jbosseapmanagedondocker_jonpostgres_1 /bin/bash
 docker exec -i -t jbosseapmanagedondocker_jonserver_1   /bin/bash

 ```

 * to see a container's log

  ```
 docker-compose logs dnsmasq
 docker-compose logs eapmaster
 docker-compose logs eapslave1
 docker-compose logs eapslave2
 docker-compose logs ewshttpd
 docker-compose logs jonpostgres
 docker-compose logs jonserver

 ```

 * to commit a change made in any container
 docker commit -m "persisting changes on FS" jbosseapmanagedondocker_eapmaster_1 rsoares/eap:latest

#Create a new Domain

demo-group
 s1
    -Djboss.node.name=node1
    #para isolar o cluster...
    	-Djboss.default.multicast.address =x.x.x.x
    	-Djboss.socket.binding.port-offset=100
    	-Djboss.default.multicast.address=230.1.0.20
    	-Djboss.messaging.group.address=231.7.0.10
    	Ref: https://access.redhat.com/solutions/649503

    jboss.mod_cluster.jvmRoute=node2 (funciona a partir do update 04)
    jvmRoute=node2 (funciona a partir do update 04)
 s2
    -Djboss.node.name=node2
    jboss.mod_cluster.jvmRoute=node2 (funciona a partir do update 04)
    jvmRoute=node2 (funciona a partir do update 04)

Deployments
    NOTE: before assign the new version deployment to the staging group, stop the group's managed servers
	name: deve ser único
	runtime name: deve ser o mesmo da versão original

#Patch Demo

* Minor release update (from 6.4.3 to 6.4.6)


#Memory Leak demo

Create a new Alert Definition for a Managed Server Resource.

For example, navigate through...
```
eap-slave2
	JBossAS7 Host Controllers
		EAP Host Controller
			Managed Servers
				EAP server1
					Server Configuration
						host=eap-slave1,server=server1,core-service=platform-mbean,type=memory
							memory
```
them...
 
 * Tab: `Alerts`
 * `New`
 * Name: `jvm-high`
 * Conditions
  * Add
   * Condition Type: `Measurement Absolute Value Threshold`
   * Metric: `Used Heap`
   * Comparator: `>`
   * Metric value: `100mb` 

```
watch curl http://apache/scalingdemo/ws/char  
curl http://apache/scalingdemo/ws/eat  
curl http://apache/scalingdemo/ws/eat/quick

curl http://172.17.0.7:8230/scalingdemo/ws/eat  
curl http://172.17.0.7:8230/scalingdemo/ws/eat/quick
```


---

#Server log event demo

 * create an alert definition
 * enable event filter using the following regex

```
.*SQLException*.|.*ORA-\d{4,5}|.*PSQLException|.*JBossResourceException: Could not create connection|.*Caused by: java.net.ConnectException: Connection timed out|.*javax.resource.ResourceException: Unable to get managed connection for*|.*java.io.IOException:*|.*UnknownHostException*
```

 * generating log entries

```
cd /home/rsoares/dev/github/devnull-tools/logspitter/cli
./logspitter \
--server 172.17.0.7 --port 8230 \
--message "ORA-00001 Error" \
--category java.sql.SQLException \
--level ERROR \
--exception "SQLException"
```

 * some real SQL Exceptions

```
Caused by: oracle.net.ns.NetException: The Network Adapter could not establish the connection
    at oracle.net.nt.ConnStrategy.execute(ConnStrategy.java:328)
    at oracle.net.resolver.AddrResolution.resolveAndExecute(AddrResolution.java:421)
    at oracle.net.ns.NSProtocol.establishConnection(NSProtocol.java:630)
    at oracle.net.ns.NSProtocol.connect(NSProtocol.java:206)
    at oracle.jdbc.driver.T4CConnection.connect(T4CConnection.java:966)
    at oracle.jdbc.driver.T4CConnection.logon(T4CConnection.java:292)
    ... 42 more
Caused by: java.net.ConnectException: Connection timed out
    at java.net.PlainSocketImpl.socketConnect(Native Method)
    at java.net.PlainSocketImpl.doConnect(PlainSocketImpl.java:333)
    at java.net.PlainSocketImpl.connectToAddress(PlainSocketImpl.java:195)
    at java.net.PlainSocketImpl.connect(PlainSocketImpl.java:182)
    at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:366)
    at java.net.Socket.connect(Socket.java:525)
    at oracle.net.nt.TcpNTAdapter.connect(TcpNTAdapter.java:120)
    at oracle.net.nt.ConnOption.connect(ConnOption.java:126)
    at oracle.net.nt.ConnStrategy.execute(ConnStrategy.java:306)
    ... 47 more
^[:q!

ORA-12505, TNS:listener does not currently know of SID given in connect descriptor


java.io.IOException: Broken pipe
        at sun.nio.ch.FileDispatcher.write0(Native Method)
        at sun.nio.ch.SocketDispatcher.write(SocketDispatcher.java:29)
        at sun.nio.ch.IOUtil.writeFromNativeBuffer(IOUtil.java:104)
        at sun.nio.ch.IOUtil.write(IOUtil.java:60)

java.io.IOException: Connection reset by peer
        at sun.nio.ch.FileDispatcher.read0(Native Method)
        at sun.nio.ch.SocketDispatcher.read(SocketDispatcher.java:21)
        at sun.nio.ch.IOUtil.readIntoNativeBuffer(IOUtil.java:233)
        at sun.nio.ch.IOUtil.read(IOUtil.java:200)
```

#Postgres DB Server demo

```
	docker exec -ti jbosseapmanagedondocker_jonpostgres_1  /bin/bash

	Connection Settings > listen host: 'jon-postgres'

	sudo passwd postgres

	# su - postgres
	$ psql
	postgres=# ALTER USER postgres PASSWORD 'password';
```

#JBoss EWS (Apache Httpd) demo

```
	docker exec -ti jbosseapmanagedondocker_ewshttpd_1  /bin/bash
	rt log
		/opt/redhat/jboss-ews-2.1/httpd/logs/main80_rt.log
	error log
		/opt/redhat/jboss-ews-2.1/httpd/logs/error_log

	Enable Augeas
	Connection Settings > SNMP Host Addr: '127.0.0.1'
```

```
Apache
	Main:80 (Virtual Host)
		Alert based on calltime > 5000ms
			Notification
				EAP CLI Script
				    server-name=???
				    group-name=???
				    ports-offset=???
					/host=eap-slave1/server-config=server-C/:add(group=grupo-1,socket-binding-group=ha-sockets,socket-binding-port-offset=0,auto-start=true)
					/host=eap-slave1/server-config=newserver:start
```

#Slow Response Time Demo

	http://apache/sleep/sleep.jsp?SLEEP_TIME=10023

#HA Domain Controller
What happens to the deployed applications if the domain controller crashes or is shutdown ?
	https://access.redhat.com/solutions/66541

High Availability of the Domain Controller in JBoss EAP 6
	https://access.redhat.com/solutions/255963

```
On Original Master
==
/host=eap-slave1/core-service=discovery-options/static-discovery=primary:add(host=master,port=9999)
/host=eap-slave1/core-service=discovery-options/static-discovery=primary:add(host=master,port=9999)

On Backup Master
==
/host=eap-slave1:write-local-domain-controller()

/host=eap-slave1:write-remote-domain-controller(host="${jboss.domain.master.address}",port="${jboss.domain.master.port:9999}",security-realm="ManagementRealm",username="admin")

 /host=eap-slave1:reload()
```

#GC Log Rotation
```
/server-group=other-server-group/jvm=default:write-attribute(name=jvm-options,value=["-verbose:gc", "-Xloggc:gc_%p_%t.log", "-XX:+UseGCLogFileRotation", "-XX:NumberOfGCLogFiles=10", "-XX:GCLogFileSize=50M","-XX:+PrintGCDetails", "-XX:+PrintGCDateStamps", "-XX:+PrintGCApplicationStoppedTime"])
```

#OutOfMemory
```
bool  HeapDumpOnOutOfMemoryError                = false                               {manageable}
ccstr HeapDumpPath                              =    
bool  CrashOnOutOfMemoryError                   = false                               {product}
bool  ExitOnOutOfMemoryError                    = false                               {product}
bool  HeapDumpOnOutOfMemoryError                = false                               {manageable}
ccstrlist OnOutOfMemoryError   
```

```
-verbose:gc -Xloggc:/opt/redhat/jboss-eap-6.4/domain/servers/gc_%p_%t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=50M -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCApplicationStoppedTime -XX:OnOutOfMemoryError="gcore -o /opt/redhat/jboss-eap-6.4/domain/servers/jvm_%p.coredump %p" 
```
