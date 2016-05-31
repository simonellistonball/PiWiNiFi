#!/bin/bash
DAYS=365
ORG='/C=US/ST=California/L=Santa Clara/O=Hortonworks/OU=PiWiNiFi Demo'

# generate a random password for the CA and store in a file
random-string()
{
  LC_CTYPE=C tr -dc "a-zA-Z0-9!@#$%^&*()_+?><~\`;'" < /dev/urandom | fold -w ${1:-32} | head -n 1
}
KEYLEN=4096

rm -rf CA
mkdir CA
mkdir CA/{certsdb,certreqs,crl,private}
touch CA/index.txt
sudo rm ca-passwd

CA_PASSWORD=$(random-string 32)
echo $CA_PASSWORD > ca-passwd
chmod 400 ca-passwd

echo "Generate CA certificate"
openssl req -new -newkey rsa:$KEYLEN -passout pass:$CA_PASSWORD -keyout CA/private/cakey.pem -out CA/careq.pem -config ./openssl.conf -subj "${ORG}/CN=CApiwinifi" -batch
echo "Generate CA"
openssl ca -batch -create_serial -out CA/cacert.pem -days $DAYS -keyfile CA/private/cakey.pem -passin pass:$CA_PASSWORD -selfsign -extensions v3_ca_has_san -config ./openssl.conf -infiles CA/careq.pem
