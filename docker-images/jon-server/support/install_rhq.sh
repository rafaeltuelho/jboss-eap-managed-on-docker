#!/bin/bash
echo "Setup starting ..."

unzip -q /tmp/jon-server-*.zip -d $SOFTWARE_INSTALL_DIR
DB_SERVER=jon-postgres
DB_PORT=5432
RHQ_SERVER_HOME=$SOFTWARE_INSTALL_DIR/jon-server-$JON_VERSION
RHQ_ADMIN_PWD="x1XwrxKuPvYUILiOnOZTLg=="

echo "Configuring RHQ/JON Server to use '$DB_SERVER' database server instead of localhost"
conn_url="s;^#\?rhq\.server\.database\.connection\-url=jdbc:postgresql.*$;rhq.server.database.connection-url=jdbc:postgresql://${DB_SERVER}:$DB_PORT/rhq;"
db_serv="s;^#\?rhq\.server\.database\.server\-name=.*$;rhq.server.database.server-name=${DB_SERVER};g"
rhq_sync="s;^#\?rhq\.sync\.endpoint\-address=false.*$;rhq.sync.endpoint-address=true;g"
auto_install="s;^#\?rhq\.autoinstall\.server\.admin\.password=.*$;rhq.autoinstall.server.admin.password=${RHQ_ADMIN_PWD};g"

hostlocal="s;^#\?rhq\.storage\.hostname=.*$;rhq.storage.hostname=jon-server;g"
seed="s;^#\?rhq\.storage\.seeds=.*$;rhq.storage.seeds=jon-server;g"

sed -i $db_serv ${RHQ_SERVER_HOME}/bin/rhq-server.properties
sed -i $conn_url ${RHQ_SERVER_HOME}/bin/rhq-server.properties
sed -i $rhq_sync ${RHQ_SERVER_HOME}/bin/rhq-server.properties
sed -i $auto_install ${RHQ_SERVER_HOME}/bin/rhq-server.properties
sed -i $hostlocal ${RHQ_SERVER_HOME}/bin/rhq-storage.properties
sed -i $seed ${RHQ_SERVER_HOME}/bin/rhq-storage.properties

sed -i 's;^jboss\.bind\.address=;jboss.bind.address=0.0.0.0;g' ${RHQ_SERVER_HOME}/bin/rhq-server.properties
sed -i 's;^rhq\.autoinstall\.public-endpoint-address=;rhq.autoinstall.public-endpoint-address=jon-server;g' ${RHQ_SERVER_HOME}/bin/rhq-server.properties

chmod a+x $RHQ_SERVER_HOME/jbossas/bin/*.sh

find /tmp -name "*jon-plugin*.zip" -exec unzip '{}' -d /tmp \;
find /tmp/jon-plugin-* -name "*.jar" -exec cp -v '{}' ${RHQ_SERVER_HOME}/plugins/ \;

rm -rf /tmp/jon-server-*.zip
rm -rf /tmp/jon-plugin-*
