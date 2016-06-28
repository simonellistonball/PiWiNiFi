#!/bin/bash

# NIFI_HOME is defined by an ENV command in the backing Dockerfile
nifi_props_file=${NIFI_HOME}/conf/nifi.properties

# Disable HTTP and enable HTTPS
sed -i -e 's|nifi.web.http.port=.*$|nifi.web.http.port=|' ${nifi_props_file}
sed -i -e "s|nifi.web.https.port=.*$|nifi.web.https.port=${NIFI_PORT}|" ${nifi_props_file}
#sed -i -e "s|nifi.web.https.host=.*$|nifi.web.https.host=${NIFI_HOST}|" ${nifi_props_file}

# Enable remote ports
sed -i -e "s|nifi.remote.input.socket.port=.*$|nifi.remote.input.socket.port=${REMOTE_PORT}|" ${nifi_props_file}
sed -i -e "s|nifi.remote.input.socket.host=.*$|nifi.remote.input.socket.host=${NIFI_HOST}|" ${nifi_props_file}

# Set banner text
sed -i -e "s|nifi.ui.banner.text=.*$|nifi.ui.banner.text=${BANNER}|" ${nifi_props_file}

[ ! -z "$NO_RESUME" ] && sed -i -e 's|nifi.flowcontroller.autoResumeState=true|nifi.flowcontroller.autoResumeState=false|' ${nifi_props_file}

if [ ! -f ${NIFI_HOME}/logs/nifi-app.log ]
then
  mkdir -p ${NIFI_HOME}/logs/
  touch ${NIFI_HOME}/logs/nifi-app.log
fi

IP=$(ip addr show eth0 | grep inet | awk '{print $2}' | cut -f 1 -d '/')

# Continuously provide logs so that 'docker logs' can produce them
tail -F ${NIFI_HOME}/logs/nifi-app.log &
${NIFI_HOME}/bin/nifi.sh run
