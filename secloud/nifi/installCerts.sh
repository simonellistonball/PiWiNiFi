#!/bin/sh

setNifiKey() {
  cmd='s|^'$1'=.*$|'$1'='$2'|g'
  sed -i '' $cmd $3
}

getPass() {
  res=$(grep $2 $1 | cut -d '=' -f2)
  echo $res
}

for a in piwinifi1 piwinifi2 piwinifi3
do
  mkdir $a
  cp cluster/* $a/
  cp piwinifi/logback.xml $a/

  setNifiKey "nifi.security.truststore" "./conf/$a.truststore.jks" "$a/nifi.properties"
  setNifiKey "nifi.security.keystore" "./conf/$a.keystore.jks" "$a/nifi.properties"

  setNifiKey "nifi.security.truststorePasswd" $(getPass certs/$a.passwd truststorePasswd ) "$a/nifi.properties"
  setNifiKey "nifi.security.keystorePasswd" $(getPass certs/$a.passwd keystorePasswd ) "$a/nifi.properties"
  setNifiKey "nifi.security.keyPasswd" $(getPass certs/$a.passwd keyPasswd ) "$a/nifi.properties"

  setNifiKey "nifi.cluster.node.address" "$a.things.simonellistonball.com" "$a/nifi.properties"
  setNifiKey "nifi.web.https.host" "$a.things.simonellistonball.com" "$a/nifi.properties"
  setNifiKey "nifi.remote.input.socket.host" "$a.things.simonellistonball.com" "$a/nifi.properties"

  cp certs/$a.* $a/
  scp $a/* $a.westus.cloudapp.azure.com:$a-conf/
done

# push up ncm config
setNifiKey "nifi.security.truststorePasswd" $(getPass certs/passwd truststorePasswd ) "piwinifi/nifi.properties"
setNifiKey "nifi.security.keystorePasswd" $(getPass certs/passwd keystorePasswd ) "piwinifi/nifi.properties"
setNifiKey "nifi.security.keyPasswd" $(getPass certs/passwd keyPasswd ) "piwinifi/nifi.properties"

ssh piwinifi.westus.cloudapp.azure.com 'mkdir ~/nifi-conf/'
scp certs/* piwinifi.westus.cloudapp.azure.com:nifi-conf/
scp piwinifi/* piwinifi.westus.cloudapp.azure.com:nifi-conf/
# push ncm configurations
ssh piwinifi.westus.cloudapp.azure.com 'echo "update"; sudo cp nifi-conf/* /opt/HDF-1.2.0.1-1/nifi/conf'

# push cluster configurations
for a in piwinifi1 piwinifi2 piwinifi3
do
  ssh $a.westus.cloudapp.azure.com mkdir $a-conf
  scp -r certs/$a.* $a.westus.cloudapp.azure.com:$a-conf/
  scp -r certs/truststore.jks $a.westus.cloudapp.azure.com:$a-conf/
  scp -r certs/keystore.jks $a.westus.cloudapp.azure.com:$a-conf/
  ssh $a.westus.cloudapp.azure.com sudo cp $a-conf/* /opt/HDF-1.2.0.1-1/nifi/conf
done
