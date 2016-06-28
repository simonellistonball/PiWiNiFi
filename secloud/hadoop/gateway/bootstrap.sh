#!/bin/sh

sudo cp gateway/hosts /etc/hosts

# bootstrap the servers
bootstrap_url=https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/ambari-bootstrap.sh
## install the ambari-server
curl -sSL ${bootstrap_url} | install_ambari_server=true sudo sh;

# push out all the other server's bootstrap
for server in $(grep -v 127.0 gateway/hosts | cut -f 2 -d ' ' | sort -u)
do
  echo -n $server...
  cat gateway/hosts | ssh -i ~/.ssh/id_azure $server "cat - | sudo tee /etc/hosts"
  ssh -tt $server "curl -sSL ${bootstrap_url} | ambari_server=piwinifigateway.local sudo sh; " &
  cat gateway/disk-prep.sh | ssh -tt -i ~/.ssh/id_azure $server sudo sh
  echo "done"
done
