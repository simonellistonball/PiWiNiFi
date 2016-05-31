#!/bin/bash

# Certificates for provisioner
cp CA/cacert.pem cloud/provisioner/certs/ca.crt
cp certs/cloud/cloud.server.crt cloud/provisioner/certs/server.crt
cp certs/cloud/cloud.server.key cloud/provisioner/certs/server.key.enc
openssl rsa -in cloud/provisioner/certs/server.key.enc -out cloud/provisioner/certs/server.key
# make a dh param file for the web server
openssl dhparam -out cloud/provisioner/certs/dh.pem 2048

# CA copy for the provisioner
cp -R CA cloud/provisioner/data/CA/
cp ca-passwd cloud/provisioner/data/

# Trust and Key Stores for the NiFis
for server in secloud cloud booth
do
  cp certs/$server/$server.server.keystore.jks $server/nifi/certs/keystore.jks
  cp certs/$server/$server.truststore.jks $server/nifi/certs/truststore.jks
  cat certs/$server/pass-* | sed 's/: /=/' > $server/nifi/certs/passwd
done
