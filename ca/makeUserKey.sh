#!/bin/bash

NAME=$1
DAYS=365
ORG='/C=US/ST=California/L=Santa Clara/O=Hortonworks/OU=PiWiNiFi Demo'
DNS='.things.simonellistonball.com'

random-string()
{
  LC_CTYPE=C tr -dc "a-zA-Z0-9!@#%^*()_+?~;'" < /dev/urandom | fold -w ${1:-32} | head -n 1
}

PASSLEN=10
KEYLEN=4096

REQPATH="users/$NAME"
rm -rf $REQPATH
mkdir -p $REQPATH

CLI_PASSWORD=$(random-string $PASSLEN)
echo $CLI_PASSWORD > ${REQPATH}/${NAME}-client-passwd
chmod 400 ${REQPATH}/${NAME}-*-passwd
keytool="keytool -noprompt"

# client keys
echo "Generate client key"
openssl genrsa -aes256 -passout pass:$CLI_PASSWORD -out $REQPATH/${NAME}.client.key $KEYLEN
echo "Generate client CSR"
openssl req -new -key $REQPATH/${NAME}.client.key -out $REQPATH/${NAME}.client.csr -passin pass:$CLI_PASSWORD -subj "${ORG}/CN=${NAME}"
echo "Signing client certificate"
openssl ca -batch -config openssl.conf -passin file:ca-passwd -out $REQPATH/${NAME}.client.crt -infiles $REQPATH/${NAME}.client.csr

# turn it into a p12
openssl pkcs12 -export -aes256 -out $REQPATH/${NAME}.p12 -passout pass:$CLI_PASSWORD -inkey $REQPATH/${NAME}.client.key -passin pass:$CLI_PASSWORD -in $REQPATH/${NAME}.client.crt -certfile CA/cacert.pem

${keytool} -importkeystore -srckeystore $REQPATH/${NAME}.p12 -srcstoretype pkcs12 -srcalias 1 -srcstorepass $CLI_PASSWORD -destkeystore $REQPATH/${NAME}.jks -deststoretype jks -deststorepass $CLI_PASSWORD -destalias ${NAME}
