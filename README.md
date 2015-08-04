# JBoss EAP Managed on Docker

Provides a complete JBoss EAP 6 environment managed by JBoss Operations Network (JON/RHQ) and load balanced/proxied by Apache Web Server (JBoss EWS with mod_cluster)

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

