#!/bin/bash

SOFTWARE_DIR="./software"
IMAGES_DIR="./docker-images"

EAP_SERVER_PKG_NAME="jboss-eap-*.zip"
EAP_NATIVE_PKG_NAME="jboss-eap-native*.zip"
EWS_HTTPD_PKG_NAME="jboss-ews-httpd*.zip"
JON_SERVER_PKG_NAME="jon-server-*.zip"
JON_PLUGIN_PKG_NAME="jon-plugin-*.zip"

#>/dev/null 2>&1

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
		PLEASE add the $USER to sudors or to docker system group ('usermod -aG docker $USER')
		or execute this script as root!" && \
   exit 1


function test_bin_pkgs(){
   find_result=$(find $SOFTWARE_DIR/ -name "$1")
   [[ -z $find_result ]] && \
    	echo -e "\t $1 file not found!
   		PLEASE download the binary package and put into software dir" && \
   	exit 1
}

function test_patch_pkgs(){
   SFW=$1
   find_result=$(find $SOFTWARE_DIR/$SFW/patch -name "*.zip")

   # if there is no patch zip files create a fake one to avoid issues with COPY instructions on Dockefiles
   [[ -z $find_result ]] && \
	touch $SOFTWARE_DIR/$SFW/patch/dummy_pkg.zip
}

echo -e "\n >>> Check the softwares required to setup the environment"
test_bin_pkgs $EAP_SERVER_PKG_NAME
test_bin_pkgs $EAP_NATIVE_PKG_NAME
test_bin_pkgs $EWS_HTTPD_PKG_NAME
test_bin_pkgs $JON_SERVER_PKG_NAME
test_bin_pkgs $JON_PLUGIN_PKG_NAME

echo -e "\t >>> extracting the rhq-agent JAR installer..."
unzip -j "$SOFTWARE_DIR/jon/jon-server*.zip" \
	"jon-server-*/modules/org/rhq/server-startup/main/deployments/rhq.ear/rhq-downloads/rhq-agent/rhq-enterprise-agent-*.jar" \
	-d software/jon

echo -e "\t >>> Check if there is patch packages..."
test_patch_pkgs "eap"
test_patch_pkgs "jon"

# avoid permission error during build process
chmod a+r $SOFTWARE_DIR/

#--------

echo -e "\n >>> ALL SET!"
echo -e "\t now you can start all the environment"
echo -e "\t from this repo's root directory enter the following command
		> docker-compose up
		wait some minutes and VOILA!"

