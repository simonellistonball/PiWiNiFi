#!/bin/bash

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

getPass() {
  grep $2 $1 | cut -d '=' -f2
}

NIFI_HOME=/opt/nifi

docker run -i -t --rm \
    -P \
    -v $(realpath ./authorized-users.xml):"${NIFI_HOME}/conf/authorized-users.xml" \
    -v $(realpath ./flow.xml.gz):"${NIFI_HOME}/conf/flow.xml.gz" \
    -v $(realpath ./certs):/opt/certs:ro \
    -v $(realpath ./repos/flowfile_repository):"${NIFI_HOME}/flowfile_repository" \
    -v $(realpath ./repos/database_repository):"${NIFI_HOME}/database_repository" \
    -v $(realpath ./repos/content_repository):"${NIFI_HOME}/content_repository" \
    -v $(realpath ./repos/provenance_repository):"${NIFI_HOME}/provenance_repository" \
    -e KEYSTORE_PASSWORD=$(getPass certs/passwd keystorePassword) \
    -e TRUSTSTORE_PASSWORD=$(getPass certs/passwd truststorePassword)  \
    -e SENSITIVE_PROPERTIES_KEY=`cat certs/sensitive_key` \
    simonellistonball/nifi
