#!/bin/sh

stack=$1
count=7
HOSTS="${stack}0[1-$count].cloud.hortonworks.com"

ambari_server=$(cut -f 1 -d " " $HOSTS)
address=http://${ambari_server}:8080/api/v1

# bootstrap the servers
bootstrap_url=https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/ambari-bootstrap.sh

## link /hadoop to /mnt to use the data disk
pdsh -w $HOSTS "ln -s /mnt /hadoop; exit;"

## install the ambari-server
pdsh -w ${ambari_server} "curl -sSL ${bootstrap_url} | install_ambari_server=true sh; exit;"

ssh ${ambari-server} 'curl https://bintray.com/sbt/rpm/rpm > /etc/yum.repos.d/bintray-sbt-rpm.repo;  yum install -y sbt'

## setup local repos
for repo in HDP-2.4 HDP-UTILS-1.1.0.20; do
    curl -sSu admin:admin http://${ambari_server}:8080/api/v1/stacks/HDP/versions/2.4/operating_systems/redhat6/repositories/${repo} -o /tmp/update-repo.txt
    sed -ir -e 's/\(public\|private\)-repo-1.hortonworks.com/sball01.cloud.hortonworks.com/g' -e '/^  "href"/d' /tmp/update-repo.txt
    curl -sSu admin:admin -H x-requested-by:sean http://${ambari_server}:8080/api/v1/stacks/HDP/versions/2.4/operating_systems/redhat6/repositories/${repo} -T /tmp/update-repo.txt
done

## install to all other nodes. See ‘man pdsh’ for the various ways to specify hosts.
pdsh -w "$HOSTS" curl -sSL ${bootstrap_url} | ambari_server=${ambari_server} sh; exit;

## wait for ambari web interface to come up
sleep 20

cat ${blueprint}-hosts.json | sed "s/%STACK%/${stack}/" > /tmp/hosts.json

curl -w "%{http_code}" -u admin:admin -H "X-Requested-By: simon" -d @${blueprint}.json -X POST $address/blueprints/${blueprint} #&& \
curl -u admin:admin -H "X-Requested-By: simon" -d @/tmp/hosts.json -X POST $address/clusters/mycluster

rm /tmp/hosts.json
