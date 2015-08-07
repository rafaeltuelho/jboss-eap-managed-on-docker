# JBoss EAP Managed on Docker

Provides a complete JBoss EAP 6 environment managed by JBoss Operations Network (JON/RHQ) and load balanced/proxied by Apache Web Server (JBoss EWS with mod_cluster)

The diagram below shows the complete enviorenment.
![The infrastructure Big picture](static/img/env_diagram.png "The Big picture")

First,

Access the https://access.redhat.com and download the following installers:
NOTE: download the latest releases!

```
jboss-eap-6.4.0.zip
jon-server-3.3.0.GA.zip
jon-server-3.3-update-03.zip
jboss-ews-httpd-2.1.0-RHEL7-x86_64.zip
jon-plugin-pack-eap-3.3.0.GA.zip
jboss-eap-6.4.2-patch.zip
jboss-eap-native-webserver-connectors-6.4.0-RHEL7-x86_64.zip
```

after download put them all inside 'software/' directory.

excute the `./prepare.sh script`

and them...

```
docker-compose up
```

NOTE 1: verify if your local system Firewall is UP/Running. If yes stop it or add a new rule to accept conncetions on `docker0` interface and UDP PORT `53` (DNS). Our dnsmasq service binds to `docker0` (usually with `172.17.42.1` addr)

NOTE2: to be able to open the services by name on your local browser add a new entry in the `/etc/resolv.conf` file.

```
sudo vim /etc/resolv.conf
nameserver 172.17.42.1
```

Now you can open the `http://jon-server:7070/` using your browser!
