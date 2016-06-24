#!/bin/bash

NAME=$1
DAYS=365
ORG='/C=US/ST=California/L=Santa Clara/O=Hortonworks/OU=PiWiNiFi Demo'
DNS='.things.simonellistonball.com'

random-string()
{
  LC_CTYPE=C tr -dc "a-zA-Z0-9!@#%^*()_+?~;'" < /dev/urandom | fold -w ${1:-32} | head -n 1
}

PASSLEN=32
KEYLEN=4096

REQPATH="certs/$NAME"
rm -rf $REQPATH
mkdir -p $REQPATH

PASSWORD=$(random-string $PASSLEN)
CLI_PASSWORD=$(random-string $PASSLEN)
echo $PASSWORD > ${REQPATH}/${NAME}-passwd
echo $CLI_PASSWORD > ${REQPATH}/${NAME}-client-passwd
chmod 400 ${REQPATH}/${NAME}-*-passwd
keytool="keytool -noprompt"

# make a set of keys for the provisioning server
echo "Generate server key"
openssl genrsa -aes256 -passout pass:$PASSWORD -out $REQPATH/${NAME}.server.key $KEYLEN
echo "Generate server CSR"
openssl req -new -key $REQPATH/${NAME}.server.key -out $REQPATH/${NAME}.server.csr -passin pass:$PASSWORD -subj "${ORG}/CN=${NAME}${DNS}"
echo "Signing server certificate"
#openssl x509 -req -days $DAYS -in ${NAME}.server.csr -CAcreateserial -CAserial ca.srl -CA ca.crt -CAkey ca.key -set_serial 01 -out ${NAME}.server.crt -passin file:../ca-passwd
openssl ca -batch -config openssl.conf -passin file:ca-passwd -out $REQPATH/${NAME}.server.crt -infiles $REQPATH/${NAME}.server.csr

# client keys for provisioning
echo "Generate client key"
openssl genrsa -aes256 -passout pass:$CLI_PASSWORD -out $REQPATH/${NAME}.client.key $KEYLEN
echo "Generate client CSR"
openssl req -new -key $REQPATH/${NAME}.client.key -out $REQPATH/${NAME}.client.csr -passin pass:$CLI_PASSWORD -subj "${ORG}/CN=${NAME}Client"
# And sign them
echo "Signing client certificate"
#openssl x509 -req -days $DAYS -in ${NAME}.client.csr -CA ca.crt -CAkey ca.key -out ${NAME}.client.crt -passin file:ca-passwd
openssl ca -batch -config openssl.conf -passin file:ca-passwd -out $REQPATH/${NAME}.client.crt -infiles $REQPATH/${NAME}.client.csr

echo "Convert to p12"
openssl pkcs12 -export -in $REQPATH/${NAME}.server.crt -inkey $REQPATH/${NAME}.server.key \
               -passin pass:$PASSWORD \
               -passout pass:$PASSWORD \
               -out $REQPATH/${NAME}.server.p12 -name ${NAME}${DNS} \
               -CAfile CA/cacert.pem -caname CApiwinifi

truststorePasswd=$(random-string 32)
keystorePasswd=$(random-string 32)
keyPasswd=${keystorePasswd}

echo "truststorePasswd: $truststorePasswd" > $REQPATH/pass-trust
echo "keystorePasswd: $keystorePasswd" > $REQPATH/pass-keystore
echo "keyPasswd: $keyPasswd" >> $REQPATH/pass-key

# create server keystore
#${keytool} -import -alias ${NAME}${DNS} -storepass $keystorePasswd -file $REQPATH/${NAME}.server.key -keystore $REQPATH/${NAME}.server.keystore.jks
echo "Import Keystore"
${keytool} -importkeystore \
        -deststorepass $keystorePasswd -destkeypass $keyPasswd -destkeystore $REQPATH/${NAME}.server.keystore.jks \
        -srckeystore $REQPATH/${NAME}.server.p12 -srcstoretype PKCS12 -srcstorepass $PASSWORD \
        -alias ${NAME}${DNS}
echo "Import CA"
${keytool} -import -alias CAcert -storepass $keystorePasswd -file CA/cacert.pem -keystore $REQPATH/${NAME}.server.keystore.jks
echo "Add client"
${keytool} -import -alias ${NAME}Client -storepass $keystorePasswd -file $REQPATH/${NAME}.client.crt -keystore $REQPATH/${NAME}.server.keystore.jks

# create truststore
echo "Import Truststore"
${keytool} -import -alias CAcert -storepass $truststorePasswd -file CA/cacert.pem -keystore $REQPATH/${NAME}.truststore.jks

# create client keystore
echo "Import clientstore"
${keytool} -import -alias ${NAME}Client -storepass $keystorePasswd -file $REQPATH/${NAME}.client.crt -keystore $REQPATH/${NAME}.client.keystore.jks
