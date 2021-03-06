#!/bin/bash
echo "INFO: Automation for Apace Installation"
##########  Variable Declarations - Start  ##########
#name of the current script
SCRIPT_NAME="automation.sh"
#version of the current script
SCRIPT_VERSION=1.0

#Author of the Script 
AUTHOR="Lakshmikanth"
S3_Bucket="upgrad-lakshmikanth"
Log_Directory="/var/log/apache2/"
timestamp=$(date '+%d%m%Y-%H%M%S')
Temp_Directory="/tmp/"

HTML_FOLDER="/var/www/html/"
Inventory_Filename="inventory.html"

echo "Performing an update of the package details and the package list at the start of the script"

sudo apt update -y

echo "Install apache if its not installed"
pkgs='apache2'
install=false
for pkg in $pkgs; do
  status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
  if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
    install=true
    break
  fi
done
if "$install"; then
  sudo apt install $pkgs
  echo "installing Apache2"
fi

echo "check the status of apache2"

service --status-all | grep apache2

echo "Restart the Apache2 Service if not started"

systemctl restart apache2.service

TAR_FILE_NAME=${AUTHOR}-httpd-logs-${timestamp}

echo $TAR_FILE_NAME

cd $Log_Directory

tar -cvf $TAR_FILE_NAME.tar *.log

size_of_the_file=$(ls -lah $TAR_FILE_NAME.tar | awk '{ print $5}')

cp $TAR_FILE_NAME.tar $Temp_Directory

cd $Temp_Directory

cd $HOME

echo "Copy the File to S3 Bucket"

aws s3 cp /$Temp_Directory/$TAR_FILE_NAME.tar s3://${S3_Bucket}/$TAR_FILE_NAME.tar

echo "Book - Keeping of the Tar File of Logs - Start"

cd $HTML_FOLDER
if [ -f "$Inventory_Filename" ];
then 
    echo "The Directory and the File Exists"
	cd $HTML_FOLDER
	echo "" >> $Inventory_Filename
	echo >> $Inventory_Filename
	echo "httpd-logs \t ${timestamp}   \t      tar   \t     $size_of_the_file" >> $Inventory_Filename
else
    echo "The File is not present"
	cd $HTML_FOLDER
	echo "" > $Inventory_Filename
	echo "Log Type    \t      Time Created    \t     Type    \t    Size" >> $Inventory_Filename
	echo >> $Inventory_Filename
	echo "httpd-logs   \t     ${timestamp}    \t     tar    \t     $size_of_the_file" >> $Inventory_Filename
fi

echo "Book - Keeping of the Tar File of Logs - End"

echo "End of Automation Script"
