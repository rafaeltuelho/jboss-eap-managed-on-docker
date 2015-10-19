# JBoss EAP Managed on Docker

## Intruduction
Provides a complete **JBoss EAP 6** environment managed by **JBoss Operations Network** (JON/RHQ) and load balanced/proxied by **Apache Httpd Server** (JBoss EWS with `mod_cluster`)

The diagram below shows the complete environment.
![The infrastructure Big picture](static/img/env_diagram.png "The Big picture")

**Wait!** With `docker` and `docker-compose` you can setup all this environment in your Laptop/Workstation **_in a few minutes and in an automated way_**. Yeah, thats the magic of Containers.

This setup gives you a whole JBoss EAP "infrastructure playground" to test, demo, workshop whatever you need to do with JBoss EAP. You have:

* **Apache Httpd Server** (JBoss EWS)
 * front-end for proxy/load balancer functions
* **JBoss EAP** (Domain Mode)
 * with two nodes (Host Slaves)
 * and two server groups
* **JBoss Operation Network** (JON)
 * to manage and monitor all the environment

So, you can do many things:
* deploy your JavaEE applications
* provision new server groups
 * provision new server instances
   * with mod_cluster you can see they automatically appear on `mod_cluster_manager` console!
* test clustering and fail over capabilities using the JBoss `full-ha` profile
* show and take advantage of `mod_cluster` capabilities
 * automatic backend node discovery
 * automatic web context mapping (during deploy/undeploy apps in a JBoss node)
 * rich and intelligent load balancing strategies
* monitor and manage all the components present in the setup:
 * app deployment
 * resource configuration
   * JBoss EAP Host Controllers
   * Apache virtual hosts
   * Postgres DB
 * resource provisioning (Bundles)
 * Alert and notification
 * Events
   * resource availability
   * server logs

and many other things JBoss EAP can offer...

---
## Prereqs

Before starting ensure your environment is suitable for this setup!
### Common reqs:
 * At least 6 gb of Mem. RAM available
 * At least 10 gb of disk available
 * Docker Engine installed
 * Docker Compose installed

### For Linux systems:
 * Firewall service running
 * PLEASE, add your `$USER` to the docker's system group:

```
  sudo groupadd docker
  sudo usermod -aG docker $USER
  sudo chown root:docker /var/run/docker.sock
```
> after that open a new terminal session to get the group changes

### For non linux systems:
 * on Mac OS X ensure you have
  * Docker Machine installed and the environment vars set on your terminal session

## Download softwares

Well lets prepare your host to build and setup all these things.

First you have to to download or clone this repository into a work directory in your host.
 * if you have `git` installed in your system:

```git clone https://github.com/rafaeltuelho/jboss-eap-managed-on-docker.git```

 * or just download the repo's zip file: Click on `Download ZIP` button located in right side of this page.

After that you need the product's binaries packages!

Access the https://access.redhat.com with your Red Hat account and download the following zip installers:

> NOTE: download the latest releases!

See some screenshots where you can find each software package on Red Hat Customer Portal.

![JBoss EAP installer](static/img/redhat-csp-jboss-1.png "JBoss EAP")
--
![JBoss EAP Natives](static/img/redhat-csp-jboss-native-2.png "JBoss EAP Natives")
--
![JBoss EAP Update Patch](static/img/redhat-csp-eap-patchs.png "JBoss EAP Patches")
--
![JON](static/img/redhat-csp-jon-4.png "JON")
--
![JON Update Patch](static/img/redhat-csp-jon-patchs.png "JON Update")
--
![JON EAP Plugin](static/img/redhat-csp-jon-for-eap.png "EAP Plugin")

At the time I was writing this guide the following versions was available:
```
jboss-eap-6.4.0.zip
jon-server-3.3.0.GA.zip
jon-server-3.3-update-03.zip
jboss-ews-httpd-2.1.0-RHEL7-x86_64.zip
jon-plugin-pack-eap-3.3.0.GA.zip
jboss-eap-6.4.2-patch.zip
jboss-eap-native-webserver-connectors-6.4.0-RHEL7-x86_64.zip
```

put them all inside the `software/` directory.

## Prepare the environment

Now execute the `./prepare.sh` script.

It will check some prereqs in your system and build all the Docker Images needed by `docker-compose` to startup the Containers.

> NOTE: the build step takes some time to finish. Be patient and wait...

> During the build process the scripts will apply any existing update/patch (if exists) to the products installation.

when the prepare step is finished you can verify the docker images in your local repository. Some thing like that:

```
> docker images
REPOSITORY             TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
rsoares/eap            latest              bcdd3e032a7e        About an hour ago   1.53 GB
rsoares/jon-server     latest              e084c057a6cc        3 days ago          2.125 GB
rsoares/ews            latest              c3fe3359bbea        3 days ago          547.1 MB
rsoares/jon-postgres   latest              0061bd278821        3 days ago          566 MB
rsoares/jon-agent      latest              62f750308407        3 days ago          497.2 MB
rsoares/java-base      latest              f0b4b37fbc5a        3 days ago          459.4 MB
rsoares/centos7-base   latest              a60bfe564a73        3 days ago          234.5 MB
rsoares/dnsmasq        latest              5e19b0dd6eb0        3 days ago          189 MB
centos                 centos7             7322fbe74aa5        7 weeks ago         172.2 MB
centos                 latest              7322fbe74aa5        7 weeks ago         172.2 MB
centos/postgresql      latest              abd6fe69720d        9 months ago        327.3 MB
```

## Startup!

after that, if all worked fine you finally can do

```
docker-compose up
```
you should see a lot of output in your console. Docker Compose start the containers in foreground (if you don't specify `-d` option).

```
> docker-compose up
Creating jbosseapmanagedondocker_dnsmasq_1...
Creating jbosseapmanagedondocker_eapmaster_1...
Creating jbosseapmanagedondocker_eapslave1_1...
Creating jbosseapmanagedondocker_jonpostgres_1...
Creating jbosseapmanagedondocker_ewshttpd_1...
Creating jbosseapmanagedondocker_eapslave2_1...
Creating jbosseapmanagedondocker_jonserver_1...
Attaching to jbosseapmanagedondocker_dnsmasq_1, jbosseapmanagedondocker_eapmaster_1, jbosseapmanagedondocker_eapslave1_1, jbosseapmanagedondocker_jonpostgres_1, jbosseapmanagedondocker_ewshttpd_1, jbosseapmanagedondocker_eapslave2_1, jbosseapmanagedondocker_jonserver_1

...

```
> it may take few minutes to `docker-compose` create all the containers. Remember the infra diagram! There are many components involved in this setup.

:bangbang: **IMPORTANT NOTE** :bangbang:

---

In most linux systems by default Docker engine uses `iptables` to create network links between containers. So PLEASE **make sure** your firewall service (`iptables` or `firewalld`) is enabled in your system.

In RHEL like systems (Fedora or CentOS) the Local Firewall normally is enabled by default. If this is your case, configure it (add a new rule) to accept connections on `docker0` interface for UDP PORT `53` (DNS).
Our `dnsmasq` service binds to `docker0` (usually with `172.17.42.1` addr) on UDP 53 port. See the Troubleshooting section bellow for more details.

---


## Access the services

To be able to access the services by name on your local browser add a new entry in your `/etc/resolv.conf` file (Docker Host).

```
sudo vim /etc/resolv.conf
nameserver 172.17.42.1
```

Now you can access the services by name:
* JON Server console: `http://jon-server:7070/`
 * login credentials: `rhqadmin/rhqadmin`

![JON](static/img/jon-server-inventory-import.png)
> NOTE: you have to manually import the discovered resource in the first time JON start monitor a given host. Select all the resource in the `Inventory > Discovery Queue` and click the Blue `Import` button.

* JBoss EAP Management Console (Doman COntroller): `http://master:9990/`
 * login credentials: `admin/jboss@123`

![EAP](static/img/eap-master-dc.png)

* Apache Httpd mod_cluster Manager: `http://apache:6666/mod_cluster_manager`

* Web App through Apache front-end: `http://apache/<webapp context root>`
![Apache](static/img/apache-mod_cluster_manager.png)
> NOTE: By default Google Chrome will note open URL with ports above 1024. Use the Firefox in this case.

To access some container shell use the `docker exec` command.

Get the container's name or id you want to access.
```
> docker-compose ps
                Name                                 Command                                 State                                  Ports
---------------------------------------------------------------------------------------------------------------------------------------------------------
jbosseapmanagedondocker_dnsmasq_1      /run.sh                                Up                                     53/tcp, 172.17.42.1:53->53/udp
jbosseapmanagedondocker_eapmaster_1    /run.sh domain --host-conf ...         Up                                     23364/tcp, 4447/tcp, 45688/tcp,
                                                                                                                     45700/tcp, 54200/tcp, 5455/tcp,
                                                                                                                     55200/tcp, 7500/tcp, 8080/tcp,
                                                                                                                     9990/tcp, 9999/tcp
jbosseapmanagedondocker_eapslave1_1    /run.sh domain --host-conf ...         Up                                     23364/tcp, 4447/tcp, 45688/tcp,
                                                                                                                     45700/tcp, 54200/tcp, 5455/tcp,
                                                                                                                     55200/tcp, 7500/tcp, 8080/tcp,
                                                                                                                     9990/tcp, 9999/tcp
jbosseapmanagedondocker_eapslave2_1    /run.sh domain --host-conf ...         Up                                     23364/tcp, 4447/tcp, 45688/tcp,
                                                                                                                     45700/tcp, 54200/tcp, 5455/tcp,
                                                                                                                     55200/tcp, 7500/tcp, 8080/tcp,
                                                                                                                     9990/tcp, 9999/tcp
jbosseapmanagedondocker_ewshttpd_1     /run.sh                                Up                                     6666/tcp, 80/tcp
jbosseapmanagedondocker_jonpostgres_   /run.sh                                Up                                     16163/tcp, 5432/tcp
1
jbosseapmanagedondocker_jonserver_1    /run.sh                                Up                                     7080/tcp

```

with the container's name or id:
```
docker exec -ti jbosseapmanagedondocker_eapmaster_1 /bin/bash
```

## Other tasks

### To see the container/service logs
```
docker-compose logs <service name, as declared in docker-compose.yml descriptor>
```

for example to see jonserver logs
```
docker-compose logs jonserver
```

### To stop all the environment use:
```
docker-compose stop|kill
```

### To cleanup the stopped images to save you disk space:
```
docker rm `sudo docker ps -qa --filter 'status=exited'`

or just

docker-compose rm
```

### To see how many resources (CPU and RAM) your containers are consuming:

```
docker stats \
  jbosseapmanagedondocker_dnsmasq_1 \
  jbosseapmanagedondocker_jonpostgres_1 \
  jbosseapmanagedondocker_jonpostgres_1 \
  jbosseapmanagedondocker_ewshttpd_1 \
  jbosseapmanagedondocker_eapmaster_1 \
  jbosseapmanagedondocker_eapslave1_1 \
  jbosseapmanagedondocker_eapslave2_1

```

You should see something like that:
```
CONTAINER                               CPU %               MEM USAGE/LIMIT     MEM %               NET I/O
jbosseapmanagedondocker_dnsmasq_1       0.00%               1.262 MB/12.11 GB   0.01%               1.046 MB/69.34 kB
jbosseapmanagedondocker_eapmaster_1     0.21%               448.4 MB/12.11 GB   3.70%               58.44 MB/44.36 MB
jbosseapmanagedondocker_eapslave1_1     0.87%               1.324 GB/12.11 GB   10.93%              57.46 MB/44.82 MB
jbosseapmanagedondocker_eapslave2_1     0.66%               1.271 GB/12.11 GB   10.50%              58.52 MB/43.84 MB
jbosseapmanagedondocker_ewshttpd_1      0.09%               186.6 MB/12.11 GB   1.54%               37.85 MB/22.32 MB
jbosseapmanagedondocker_jonpostgres_1   0.17%               320.5 MB/12.11 GB   2.65%               100.4 MB/211 MB
jbosseapmanagedondocker_jonpostgres_1   0.17%               320.5 MB/12.11 GB   2.65%               100.4 MB/211 MB
```

## Troubleshooting

### Tested environments

* **RHEL 7.x**
 * Docker engine 1.8
 * Docker Compose 1.3

* **Fedora Workstation 22**
  * Docker Engine 1.8
  * Docker Compose 1.2

* **Mac OS X Yosemite (10.10)**
 * Docke Engine 1.8
 * Docker Machine 0.4.1
 * Docker Compose 1.4.2
 * VirtualBox 5.x

### dnsmasq service does not starts correctly

The `dnsmasq` service container is a critical piece in this setup. Without the proper setup of this service the intercommunication between other services will not work correctly.

The `dnsmaq` container will try to bind to the `docker0` network ifc and listen to `53` UDP port. You may experience some issues with your firewall service default policy.

#### Instructions for a RHEL 7 based (CentOS, Fedora, etc) host...

In my case I used the graphical firewall configuration tool (hit `sudo firewall-config` in your shell console to open the tool) to apply this rule. See my screenshots:

![accept dns traffic](https://rafaeltuelho.files.wordpress.com/2015/10/rhel7-firewall-config-dns.png)
![trust on docker0 ifct](https://rafaeltuelho.files.wordpress.com/2015/10/rhel8-firewall-config-docker0-ifc.png)

or use the following commands in your shell

```
sudo firewall-cmd --zone=trusted --add-service-dns
sudo firewall-cmd --zone=trusted --permanent --add-service-dns
sudo firewall-cmd --zone=trusted --change-interface=docker0
sudo firewall-cmd --zone=trusted --permanent --change-interface=docker0
```

### Docker Compose stops its execution due some error during containers startup.

This can occurs in case the containers can't talk/reach each other. See the previous section (`dnsmasq` and `firewall` policy).

If your `docker-compose up` command stops, don't try to hit `docker-compose up`.

First remove the current containers instances

```
docker-compose rm
```

after doing the troubleshooting try to do
```
docker-compose up
```
again


### Updating you local repo to get the latest changes

If you update your local `git repo` with the latest changes doing:
```
git pull
```
in root of your local repo directory

you have to run the `prepare.sh` script again in order to rebuild your local Docker images.

### Can't resolve the services by name

Ensure you have changed your `/etc/resolv.conf` to add an entry to the `dnsmasq` service:
```
# Generated by NetworkManager
search localdomain
nameserver 172.17.42.1
nameserver <your gateway or corporate dns server>
nameserver 8.8.8.8
```

Note that this file is dynamically updated by the `NetworkManager` service on your host.
Every time occurs a change in your host network connection this file will lost our `dnsmasq` entry.

### Wait for the complete JON Server startup

See the jonserver service logs. When you see something like that:

```
jonserver_1 | 19:32:51,533 INFO  [org.rhq.enterprise.server.core.StartupBean] (pool-6-thread-1) --------------------------------------------------
jonserver_1 | 19:32:51,534 INFO  [org.rhq.enterprise.server.core.StartupBean] (pool-6-thread-1) JBoss Operations Network 3.3.0.GA (build edc324f:119e8f4) Server started.
jonserver_1 | 19:32:51,534 INFO  [org.rhq.enterprise.server.core.StartupBean] (pool-6-thread-1) --------------------------------------------------
jonserver_1 | 19:32:53,547 INFO  [org.rhq.helpers.rtfilter.filter.RtFilter] (http-/0.0.0.0:7080-1) --
```

your jonserver service is ready. Access its console using your browser: https://jonserver:7070/

### JON Agents (rhq-agent) registration

After JON Server startup the agents starts its registrations. Look in the JON Server's log an see something like that:

```
jonserver_1 | 19:33:07,389 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-7) Got agent registration request for new agent: jon-server[172.17.0.7:16163][4.12.0.JON330GA(119e8f4)]
jonserver_1 | 19:33:07,531 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-8) Agent [jon-server][4.12.0.JON330GA(119e8f4)] would like to connect to this server
jonserver_1 | 19:33:07,724 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-8) Agent [jon-server] has connected to this server at Sun Oct 18 19:33:07 UTC 2015
jonserver_1 | 19:33:11,995 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-9) Got agent registration request for new agent: apache[172.17.0.5:16163][4.12.0.JON330GA(119e8f4)]
jonserver_1 | 19:33:12,688 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-9) Agent [apache][4.12.0.JON330GA(119e8f4)] would like to connect to this server
jonserver_1 | 19:33:12,892 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-10) Got agent registration request for new agent: jon-postgres[172.17.0.4:16163][4.12.0.JON330GA(119e8f4)]
jonserver_1 | 19:33:13,211 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-9) Agent [apache] has connected to this server at Sun Oct 18 19:33:13 UTC 2015
jonserver_1 | 19:33:13,509 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-10) Agent [jon-postgres][4.12.0.JON330GA(119e8f4)] would like to connect to this server
jonserver_1 | 19:33:13,717 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-11) Got agent registration request for new agent: master[172.17.0.2:16163][4.12.0.JON330GA(119e8f4)]
jonserver_1 | 19:33:14,268 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-10) Agent [jon-postgres] has connected to this server at Sun Oct 18 19:33:14 UTC 2015
jonserver_1 | 19:33:14,540 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-11) Agent [master][4.12.0.JON330GA(119e8f4)] would like to connect to this server
jonserver_1 | 19:33:15,185 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-11) Agent [master] has connected to this server at Sun Oct 18 19:33:15 UTC 2015
jonserver_1 | 19:33:42,546 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-8) Got agent registration request for new agent: eap-slave1[172.17.0.3:16163][4.12.0.JON330GA(119e8f4)]
jonserver_1 | 19:33:44,582 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-8) Agent [eap-slave1][4.12.0.JON330GA(119e8f4)] would like to connect to this server
jonserver_1 | 19:33:44,810 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-7) Got agent registration request for new agent: eap-slave2[172.17.0.6:16163][4.12.0.JON330GA(119e8f4)]
jonserver_1 | 19:33:46,526 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-7) Agent [eap-slave2][4.12.0.JON330GA(119e8f4)] would like to connect to this server
jonserver_1 | 19:33:46,555 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-8) Agent [eap-slave1] has connected to this server at Sun Oct 18 19:33:46 UTC 2015
jonserver_1 | 19:33:48,224 INFO  [org.rhq.enterprise.server.core.CoreServerServiceImpl] (http-/0.0.0.0:7080-7) Agent [eap-slave2] has connected to this server at Sun Oct 18 19:33:48 UTC 2015
```

### Log exceptions on JON Server startup

If you see some exception like this excerpt on JON Server logs don't worry.

```
jonserver_1   | 20:18:34,870 ERROR [org.rhq.enterprise.server.installer.Installer] The installer will now exit due to previous errors: java.lang.Exception: Cannot obtain client connection to the RHQ app server!!

...

jonserver_1   | Caused by: java.net.ConnectException: JBAS012174: Could not connect to remote://127.0.0.1:9999. The connection failed
jonserver_1   | 	at org.jboss.as.protocol.ProtocolConnectionUtils.connectSync(ProtocolConnectionUtils.java:129) [jboss-as-protocol-7.4.0.Final-redhat-19.jar:7.4.0.Final-redhat-19]

...

jonserver_1   | Caused by: java.net.ConnectException: Connection refused
jonserver_1   | 	at sun.nio.ch.SocketChannelImpl.checkConnect(Native Method) [rt.jar:1.7.0_85]
jonserver_1   | 	at sun.nio.ch.SocketChannelImpl.finishConnect(SocketChannelImpl.java:744) [rt.jar:1.7.0_85]
```

### Log exceptions on EAP slaves

If you see some exception like this excerpt on EAp slaves' logs don't worry.

```
apslave1_1 | [Server:server-two] 20:18:15,091 ERROR [org.hornetq.core.server] (Old I/O server worker (parentId: 1197785567, [id: 0x4764c1df, /0.0.0.0:5595])) HQ224018: Failed to create session: HornetQException[errorType=CLUSTER_SECURITY_EXCEPTION message=HQ119099: Unable to authenticate cluster user: HORNETQ.CLUSTER.ADMIN.USER]
```
