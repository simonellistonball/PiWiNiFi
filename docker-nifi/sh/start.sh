#!/bin/bash

# NIFI_HOME is defined by an ENV command in the backing Dockerfile
nifi_props_file=${NIFI_HOME}/conf/nifi.properties

sed -i -e 's|^nifi.sensitive.props.key=.*$|nifi.sensitive.props.key='${SENSITIVE_PROPERTIES_KEY}'|' ${nifi_props_file}

sed -i -e 's|^nifi.security.keystore=.*$|nifi.security.keystore=/opt/certs/keystore.jks|' ${nifi_props_file}
sed -i -e 's|^nifi.security.keystoreType=.*$|nifi.security.keystoreType=jks|' ${nifi_props_file}
sed -i -e 's|^nifi.security.keystorePasswd=.*$|nifi.security.keystorePasswd='${KEYSTORE_PASSWORD}'|' ${nifi_props_file}
sed -i -e 's|^nifi.security.keyPasswd=.*$|nifi.security.keyPasswd='${KEYSTORE_PASSWORD}'|' ${nifi_props_file}

sed -i -e 's|^nifi.security.truststore=.*$|nifi.security.truststore=/opt/certs/truststore.jks|' ${nifi_props_file}
sed -i -e 's|^nifi.security.truststoreType=.*$|nifi.security.truststoreType=jks|' ${nifi_props_file}
sed -i -e 's|^nifi.security.truststorePasswd=.*$|nifi.security.truststorePasswd='${TRUSTSTORE_PASSWORD}'|' ${nifi_props_file}

# Disable HTTP and enable HTTPS
sed -i -e 's|nifi.web.http.port=.*$|nifi.web.http.port=|' ${nifi_props_file}
sed -i -e 's|nifi.web.https.port=.*$|nifi.web.https.port=${NIFI_PORT}|' ${nifi_props_file}

# Enable remote ports
sed -i -e 's|nifi.remote.input.socket.port=.*$|nifi.remote.input.socket.port=${REMOTE_PORT}|' ${nifi_props_file}
sed -i -e "s|nifi.remote.input.socket.host=.*$|nifi.remote.input.socket.host=${HOSTNAME}|" ${nifi_props_file}

sed -i -e "s|nifi.security.needClientAuth=.*$|nifi.security.needClientAuth=true|" ${nifi_props_file}

sed -i -e "s|nifi.ui.banner.text=.*$|nifi.ui.banner.text=${BANNER}|" ${nifi_props_file}

if [ ! -f ${NIFI_HOME}/logs/nifi-app.log ]
then
  mkdir -p ${NIFI_HOME}/logs/
  touch ${NIFI_HOME}/logs/nifi-app.log
fi

# Continuously provide logs so that 'docker logs' can produce them
tail -F ${NIFI_HOME}/logs/nifi-app.log &
${NIFI_HOME}/bin/nifi.sh run
