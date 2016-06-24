#!/bin/bash
REMOTE_PORT=8448
NIFI_PORT=8447

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

getPass() {
  res=$(grep $2 $1 | cut -d '=' -f2)
  #echo '"'$res'"'
  echo $res
}

NIFI_HOME=/opt/nifi

nifi_props_file=conf/nifi.properties

setNifiKey() {
  cmd='s|^'$1'=.*$|'$1'='$2'|g'
  sed -i -e  $cmd ${nifi_props_file}
}

# Set the passwords and security settings in the nifi.properties
setNifiKey "nifi.security.keystore" "/opt/certs/keystore.jks"
setNifiKey "nifi.security.truststore" "/opt/certs/truststore.jks"
setNifiKey "nifi.security.keystoreType" "jks"
setNifiKey "nifi.security.truststoreType" "jks"
setNifiKey "nifi.security.keyPasswd" $(getPass certs/passwd keyPasswd)
setNifiKey "nifi.security.keystorePasswd" $(getPass certs/passwd keystorePasswd)
setNifiKey "nifi.security.truststorePasswd" $(getPass certs/passwd truststorePasswd)
setNifiKey "nifi.security.needClientAuth" "true"

docker run -i -t --rm \
    -v $(realpath ./conf):"${NIFI_HOME}/conf" \
    -v $(realpath ./custom):"${NIFI_HOME}/custom" \
    -v $(realpath ./certs):/opt/certs:ro \
    -v $(realpath ./repos/flowfile_repository):"${NIFI_HOME}/flowfile_repository" \
    -v $(realpath ./repos/database_repository):"${NIFI_HOME}/database_repository" \
    -v $(realpath ./repos/content_repository):"${NIFI_HOME}/content_repository" \
    -v $(realpath ./repos/provenance_repository):"${NIFI_HOME}/provenance_repository" \
    -e NIFI_PORT=${NIFI_PORT} \
    -e REMOTE_PORT=${REMOTE_PORT} \
    -e BANNER="Booth Nifi" \
    -p ${NIFI_PORT}:${NIFI_PORT} \
    -p ${REMOTE_PORT}:${REMOTE_PORT} \
    --ulimit nofile=50000:50000 \
    --ulimit nproc=10000:10000 \
    simonellistonball/nifi $1
