#!/bin/sh

SERVER=$1
shift
STORE=$1
shift

TYPE=$(echo $STORE | cut -d "." -f 2)
TYPE=${TYPE:-$1}

echo $TYPE
echo keytool -keystore certs/${SERVER}/${SERVER}.${STORE}.jks -storepass $(cat certs/${SERVER}/pass* | grep ${TYPE}Passwd | cut -d ' ' -f2) $*

keytool -keystore certs/${SERVER}/${SERVER}.${STORE}.jks -storepass $(cat certs/${SERVER}/pass* | grep ${TYPE}Passwd | cut -d ' ' -f2) $*
