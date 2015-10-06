#!/bin/bash

SOFTWARE_DIR="./software"
IMAGES_DIR="./docker-images"
USER_TAG_NAME="rsoares"

EAP_SERVER_PKG_NAME="jboss-eap-*.zip"
EAP_PATCH_PKG_NAME="jboss-eap-*-patch*.zip"
EAP_NATIVE_PKG_NAME="jboss-eap-native*.zip"
EWS_HTTPD_PKG_NAME="jboss-ews-httpd*.zip"
JON_SERVER_PKG_NAME="jon-server-*.zip"
JON_UPDATE_PKG_NAME="jon-server-*-update-*.zip"
JON_PLUGIN_PKG_NAME="jon-plugin-*.zip"
RHQ_AGENT_PKG_NAME="rhq-enterprise-agent*.jar"

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
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

echo -e "\n >>> Test if docker and compose is installed..."
docker --version
[[ $? != 0 ]] && echo -e "\tdocker engine not installed or not present in your PATH" && exit 1
docker-compose --version
[[ $? != 0 ]] && echo -e "\tdocker-compose not installed or not present in your PATH" && exit 1
docker images >/dev/null 2>&1
[[ $? != 0 ]] && \
   echo -e "\t ups! It appears you ($USER) can't execute docker commands.
                If you are running on Linux: 
		\tPLEASE add the $USER to sudors or add it to docker's system group ('usermod -aG docker $USER')
		or execute this script as root!
                If you are runing on Mac OS X:
                \tPLEASE make shure your boot2Docker or docker-machine is started!" && \
   exit 1


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
   fi
}

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

# avoid permission error during build process
chmod a+rx $SOFTWARE_DIR/*

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
echo -e "\t now you can start all the environment"
echo -e "\t from this repo's root directory enter the following command
		> docker-compose up
		wait some minutes and VOILA!
<-----"

