#!/bin/bash

RHQ_SERVER_HOME="$SOFTWARE_INSTALL_DIR/jon-server-$JON_VERSION"
PATCH_DIR="/tmp/patch"
PATCH_NAME_PATTERN="jon-server-*update*.zip"

if [ -d "$PATCH_DIR" ]; then 

   #ensure get the most recent
   PATCH_FILE=$(find $PATCH_DIR -type f -name $PATCH_NAME_PATTERN | sort -nr | head -1)

   if [ -f "$PATCH_FILE" ] && [ -s "$PATCH_FILE" ] && [ -r "$PATCH_FILE" ]; then
       echo "the $PATCH_FILE will be applied to this installation" 
       cd $PATCH_DIR
       unzip -q $PATCH_FILE
       cd $(find . -maxdepth 1 -type d -name "jon*update*" -print0)

       bash ./apply-updates.sh $RHQ_SERVER_HOME
   else
      echo "no valid JON Server patch found!"
   fi
  
   echo "deleting Patches"
   rm -rf $PATCH_DIR

fi
