#!/bin/bash

SOFTWARE_DIR="./software"
IMAGES_DIR="./docker-images"
USER_TAG_NAME="rsoares"
DOCKER0_NETIFC_DEFAULT_ADDR="172.17.42.1"

EAP_SERVER_PKG_NAME="jboss-eap-*.zip"
EAP_PATCH_PKG_NAME="jboss-eap-*-patch*.zip"
EAP_NATIVE_PKG_NAME="jboss-eap-native*.zip"
EWS_HTTPD_PKG_NAME="jboss-ews-httpd*.zip"
JON_SERVER_PKG_NAME="jon-server-*.zip"
JON_UPDATE_PKG_NAME="jon-server-*-update-*.zip"
JON_PLUGIN_PKG_NAME="jon-plugin-*.zip"
RHQ_AGENT_PKG_NAME="rhq-enterprise-agent*.jar"

RED='\033[0;31m'
ORG='\033[0;33m'
NC='\033[0m' # No Color

echo -e "\n This setup needs the following softwares packages (zip files):
	* JBoss EAP 6.x
	\t** JBoss EAP paches  (OPTIONAL)
	\t** JBoss EAP Natives (for your platform, eg: Linux x86_64) 
	\t** JBoss EWS 2 Httpd (for your platform, eg: Linux x86_64) 
	* JBoss ON 3.x
	\t** JON Pluggin Pack for EAP
	\t** JON paches  (OPTIONAL)
 Before continue access the Red Hat Customer Portal (https://access.redhat.com): 
  * download all the packages listed above and
  * put them in its respective directories inside 'software/' \n"

read -e -p " Want to continue (Y,n)?" -n 1 -r
echo
[[ ! "$REPLY" =~ ^[Yy]$ ]] && exit 1

echo -e "\n >>> Test if docker and compose is installed..."
docker --version
[[ $? != 0 ]] && echo -e "\tdocker engine not installed or not present in your PATH" && exit 1
docker-compose --version
[[ $? != 0 ]] && echo -e "\tdocker-compose not installed or not present in your PATH" && exit 1


if [[ ! "$OSTYPE" == "linux"* ]]; # host not linux like
then
   echo
   echo -e "It appears your host is not a Linux OS. Let's check if your have Docker Machine/Boot2Docker"
   echo 

   docker-machine --version
   [[ $? != 0 ]] && \
	echo -e "\tdocker-machine not installed or not present in your PATH\n
                 \tPLEASE make shure your docker-machine instance is started and execute\n 
                 \t\t eval \"\$(docker-machine env <machine instance name>)\" " && \
	exit 1
   
   echo
   
   docker-machine ls
   echo -e "\n\t ENSURE your docker-machine instance have enough Disk and RAM mem available to run this setup. I recomend at least 20gb Disk and 4gb RAM"

else

   # Verify the IP ADDR for the docker0 network bridge
   current_docker0_addr=$(ip addr show docker0 | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
   if [[ ! "$DOCKER0_NETIFC_DEFAULT_ADDR" == "$current_docker0_addr"  ]];
   then
	echo -e "\n\t ${ORG}It appears your 'docker0' network bridge got a different IP Addr: $current_docker0_addr"
	echo -e "\t\t ${ORG} in this case we need to change the 'docker-compose.yml' descriptor to use this addr as dnsmasq bind addr."
        sed_expr="s/$DOCKER0_NETIFC_DEFAULT_ADDR/$current_docker0_addr/g"
        sed -i.bkp $sed_expr ./docker-compose.yml
   else
	echo -e "\n\t ${ORG}'docker0' network bridge IP Addr: $current_docker0_addr \n"
   fi
fi

#read
tput sgr0

docker images >/dev/null 2>&1
[[ $? != 0 ]] && \
   echo -e "\t ups! It appears you ($USER) can't execute docker commands.
                If you are running on Linux:
                ENSURE your docker engine daemon service is running. 
                \t on RHEL 7: > sudo systemctl start docker \n
		PLEASE add the $USER to the  docker's system group:\n\n
                \tsudo groupadd docker
                \tsudo usermod -aG docker $USER
                \tsudo chown root:docker /var/run/docker.sock \n
                \tnow open a new terminal session and execute this script again\n\n
		\tor execute this script as root using sudo!" && exit 1


function test_bin_pkgs(){
   # in case the pkgs was moved to their docker-images dirs before. Bring them back to the software dir
   ./reverse_packages.sh

   find_result=$(find $SOFTWARE_DIR/ -name "$1")
   [[ -z $find_result ]] && \
    	echo -e "\t $1 file not found!
   		PLEASE download the binary package and put into software dir" && \
   	exit 1
}

function build_image(){
   IMG_NAME="${1}"

   #test if the image is already on local docker repo
   docker images | grep "$USER_TAG_NAME/$IMG_NAME" >/dev/null 2>&1
   if [ $? != 0 ] # image not found in the local repo
   then
      echo -e "----->
	\t '$USER_TAG_NAME/$IMG_NAME' not found on local docker repo. 
	\t\t I will try to build it \n<-----\n"

      [[ ! -f $IMAGES_DIR/$IMG_NAME/Dockerfile ]] && \
   	echo -e "\t Dockerfile not found for base image: $IMG_NAME" && \
	exit 1
      
      docker build -t "$USER_TAG_NAME/$IMG_NAME" $IMAGES_DIR/$IMG_NAME
   else
      echo -e "\n\t ${ORG}The image \"${USER_TAG_NAME}/${IMG_NAME}\" was found in your local docker registry!\n"
      tput sgr0
      read -e -p " Want to REBUILD it(N,y)?" -n 1 -r
      echo
      [[ $REPLY =~ ^[Yy]$ ]] && \
	      docker build -t "$USER_TAG_NAME/$IMG_NAME" $IMAGES_DIR/$IMG_NAME
   fi
}

# avoid permission error during build process
chmod a+rx $SOFTWARE_DIR/*

echo -e "\n >>> Check the softwares required to setup the environment"
test_bin_pkgs $EAP_SERVER_PKG_NAME
#test_bin_pkgs $EAP_PATCH_PKG_NAME
test_bin_pkgs $EAP_NATIVE_PKG_NAME
test_bin_pkgs $EWS_HTTPD_PKG_NAME
test_bin_pkgs $JON_SERVER_PKG_NAME
#test_bin_pkgs $JON_UPDATE_PKG_NAME
test_bin_pkgs $JON_PLUGIN_PKG_NAME

echo -e "\n >>> extracting the rhq-agent JAR installer..."
unzip -j "$SOFTWARE_DIR/$JON_UPDATE_PKG_NAME" \
	"jon-server-*/modules/org/rhq/server-startup/main/deployments/rhq.ear/rhq-downloads/rhq-agent/rhq-enterprise-agent-*.jar" \
	-d software/

echo -e "\n >>> Move the zip pkgs files to its respective image's DIRs"
# this is necessary because Dockerfile COPY does not support relative paths (../somepath)

cp $SOFTWARE_DIR/$RHQ_AGENT_PKG_NAME  $IMAGES_DIR/jon-agent/software/
mv $SOFTWARE_DIR/$RHQ_AGENT_PKG_NAME  $IMAGES_DIR/jon-postgres/software/

mv $SOFTWARE_DIR/$JON_UPDATE_PKG_NAME $IMAGES_DIR/jon-server/software/patch/ >/dev/null 2>&1
mv $SOFTWARE_DIR/$JON_PLUGIN_PKG_NAME $IMAGES_DIR/jon-server/software/
mv $SOFTWARE_DIR/$JON_SERVER_PKG_NAME $IMAGES_DIR/jon-server/software/

mv $SOFTWARE_DIR/$EAP_NATIVE_PKG_NAME $IMAGES_DIR/ews/software/
mv $SOFTWARE_DIR/$EWS_HTTPD_PKG_NAME  $IMAGES_DIR/ews/software/

mv $SOFTWARE_DIR/$EAP_PATCH_PKG_NAME  $IMAGES_DIR/eap/software/patch/ >/dev/null 2>&1
mv $SOFTWARE_DIR/$EAP_SERVER_PKG_NAME $IMAGES_DIR/eap/software/

echo -e "\n >>> Build images..."
echo -e "\n\t *** This step takes some minutes to finish... PLEASE WAIT...\n"
build_image "centos7-base"
build_image "java-base"
build_image "dnsmasq"
build_image "jon-agent"
build_image "jon-postgres"
build_image "jon-server"
build_image "ews"
build_image "eap"

echo -e "\n----->"
echo -e " >>> ALL SET!"
echo -e "\t now you can start all tyyhe environment"
echo -e "\t from this repo's root directory enter the following command
		> docker-compose up
		wait some minutes and VOILA!
<-----"

echo -e "\n\t Remember to add an entry in your /etc/resolv.conf: \n
		nameserver 172.17.42.1"
