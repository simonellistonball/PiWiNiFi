#!/bin/bash

NAME=$1
location=/data/keys/$NAME

rm -rf $location
mkdir -p $location

ca=/data/CA
DAYS=30
KEYLEN=2048

keytool="/usr/local/java/jdk1.8.0_91/bin/keytool -noprompt"
DNS=$2.things.simonellistonball.com
ORG='/C=US/ST=California/O=Hortonworks/OU=PiWiNiFi Demo'

# build the trust and keystore files for each server
truststorePasswd=$3
keystorePasswd=$4
# keypassword and keystore password must be the same, for reasons
keyPasswd=$4

echo "{"
echo "\"truststorePasswd\": \"$truststorePasswd\","
echo "\"keystorePasswd\": \"$keystorePasswd\","
echo "\"keyPasswd\": \"$keyPasswd\","

PASSWORD=$keystorePasswd
CLI_PASSWORD=$keyPasswd

function log {
  echo "$(date) $1: $2" >> /var/log/keys.log
}

# make a set of keys for the provisioning server
log "Generate server key"
openssl genrsa -aes256 -passout pass:$PASSWORD -out $location/${NAME}.server.key $KEYLEN
log "Generate server CSR"
openssl req -new -key $location/${NAME}.server.key -out $location/${NAME}.server.csr -passin pass:$PASSWORD -subj "${ORG}/CN=${NAME}${DNS}"
log "Signing server certificate"
openssl ca -batch -config /data/openssl.conf -passin file:/data/ca-passwd -out $location/${NAME}.server.crt -infiles $location/${NAME}.server.csr

# client keys for provisioning
log "Generate client key"
openssl genrsa -aes256 -passout pass:$CLI_PASSWORD -out $location/${NAME}.client.key $KEYLEN
log "Generate client CSR"
openssl req -new -key $location/${NAME}.client.key -out $location/${NAME}.client.csr -passin pass:$CLI_PASSWORD -subj "${ORG}/CN=${NAME}Client"
# And sign them
log "Signing client certificate"
openssl ca -batch -config /data/openssl.conf -passin file:/data/ca-passwd -out $location/${NAME}.client.crt -infiles $location/${NAME}.client.csr

# create server keystore
${keytool} -import -alias ${NAME}${DNS} -storepass $keystorePasswd -file $location/${NAME}.server.crt -keystore $location/${NAME}.server.keystore.jks

# create truststore
${keytool} -import -alias CAcert -storepass $truststorePasswd -file /data/CA/cacert.pem -keystore $location/${NAME}.truststore.jks

# create client keystore
${keytool} -import -alias ${NAME}Client -storepass $keystorePasswd -file $location/${NAME}.client.crt -keystore $location/${NAME}.client.keystore.jks

clientKeystoreContent=$(openssl enc -A -base64 < ${NAME}.client.keystore.jks)
serverKeystoreContent=$(openssl enc -A -base64 < ${NAME}.server.keystore.jks)
trustContent=$(openssl enc -A -base64 < ${NAME}.server.truststore.jks)

echo "\"clientKeystore\": \"$clientKeystoreContent\","
echo "\"serverKeystore\": \"$serverKeystoreContent\","
echo "\"trustStore\": \"$trustContent\""
echo "}"

exit 0
