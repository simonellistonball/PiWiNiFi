#!/bin/bash

# Certificates for provisioner
chmod 700 ../cloud/provisioner/certs/ca.crt
cp CA/cacert.pem ../cloud/provisioner/certs/ca.crt
cp certs/cloud/cloud.server.crt ../cloud/provisioner/certs/server.crt
openssl rsa -in certs/cloud/cloud.server.key -passin file:certs/cloud/cloud-passwd -out ../cloud/provisioner/certs/server.key
# make a dh param file for the web server
[ ! -f ../cloud/provisioner/certs/dh.pem ] && openssl dhparam -out ../cloud/provisioner/certs/dh.pem 2048

# CA copy for the provisioner
chmod 700 ../cloud/provisioner/data/ca-passwd

rm -rf ../cloud/provisioner/data/CA/
cp -R CA ../cloud/provisioner/data/CA/
cp ca-passwd ../cloud/provisioner/data/

# Trust and Key Stores for the NiFis
for server in secloud cloud booth
do
  rm -rf ../$server/nifi/certs/
  mkdir ../$server/nifi/certs/
  cp certs/$server/$server.client.keystore.jks ../$server/nifi/certs/client.keystore.jks
  cp certs/$server/$server.server.keystore.jks ../$server/nifi/certs/keystore.jks
  cp certs/$server/$server.truststore.jks ../$server/nifi/certs/truststore.jks
  cat certs/$server/pass-* | sed 's/: /=/' > ../$server/nifi/certs/passwd
done

for server in piwinifi1 piwinifi2 piwinifi3
do
  mkdir -p ../secloud/nifi/certs/
  cp certs/$server/$server.server.keystore.jks ../secloud/nifi/certs/$server.keystore.jks
  cp certs/$server/$server.truststore.jks ../secloud/nifi/certs/$server.truststore.jks
  cat certs/$server/pass-* | sed 's/: /=/' > ../secloud/nifi/certs/$server.passwd
done
