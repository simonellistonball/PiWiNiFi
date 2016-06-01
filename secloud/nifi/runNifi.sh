#!/bin/bash

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

getPass() {
  grep $2 $1 | cut -d '=' -f2
}

NIFI_HOME=/opt/nifi

REMOTE_PORT=8446
NIFI_PORT=8445

echo $(getPass certs/passwd keystorePasswd)

docker run -i -t --rm \
    -v $(realpath ./authorized-users.xml):"${NIFI_HOME}/conf/authorized-users.xml" \
    -v $(realpath ./bootstrap.conf):"${NIFI_HOME}/conf/bootstrap.conf" \
    -v $(realpath ./flow.xml.gz):"${NIFI_HOME}/conf/flow.xml.gz" \
    -v $(realpath ./custom):"${NIFI_HOME}/custom" \
    -v $(realpath ./certs):/opt/certs:ro \
    -v $(realpath ./repos/flowfile_repository):"${NIFI_HOME}/flowfile_repository" \
    -v $(realpath ./repos/database_repository):"${NIFI_HOME}/database_repository" \
    -v $(realpath ./repos/content_repository):"${NIFI_HOME}/content_repository" \
    -v $(realpath ./repos/provenance_repository):"${NIFI_HOME}/provenance_repository" \
    -e KEYSTORE_PASSWORD=$(getPass certs/passwd keystorePasswd) \
    -e TRUSTSTORE_PASSWORD=$(getPass certs/passwd truststorePasswd)  \
    -e NIFI_PORT=${NIFI_PORT} \
    -e REMOTE_PORT=${REMOTE_PORT} \
    -e BANNER="Data Center Nifi" \
    -p ${NIFI_PORT}:${NIFI_PORT} \
    -p ${REMOTE_PORT}:${REMOTE_PORT} \
    simonellistonball/nifi $1
