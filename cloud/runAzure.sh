#!/bin/bash

# setup and run all the dockers in Azure
docker-machine create piwinificloud \
  --driver azure \
  --azure-subscription-id 55a6ad34-6019-4d49-bbc8-709fc346f2cf \
  --azure-resource-group sballPiWiNiFi \
  --azure-size Standard_A3 \
  --azure-location westus \
  --azure-vnet hadoopVnet \
  --azure-subnet hadoopSubnet \
  --azure-subnet-prefix 10.0.0.0/24 \
  --azure-private-ip-address 10.0.0.100 \
  --azure-open-port 8443 \
  --azure-open-port 8444 \
  --azure-open-port 443

eval $(docker-machine env piwinificloud)

docker-machine ssh piwinificloud mkdir -p data/cloud

# copy the relevant volumes to the docker-machine
docker-machine scp -r nifi/conf piwinificloud:data/cloud/
docker-machine scp -r nifi/certs piwinificloud:data/cloud/
docker-machine scp -r nifi/custom piwinificloud:data/cloud/

docker-machine scp -r provisioner/certs piwinificloud:data/provisioner/
docker-machine scp -r provisioner/data piwinificloud:data/provisioner/

docker-machine ssh piwinificloud "mkdir -p data/cloud/repos/flowfile_repository data/cloud/repos/content_repository data/cloud/repos/database_repository"
# run the nifi container
cd nifi
if [ ! $(docker ps | grep --silent simonellistonball/nifi) ]
then
  ./runNifi.sh /home/docker-user/data/cloud
fi

cd ../provisioner
if [ ! $(docker ps | grep --silent simonellistonball/provisioner) ]
then
  ./runProvisioning.sh /home/docker-user/data/provisioner
fi

cd ..

# update the DNS to point to the machine
echo "Cloud parts of PiWiNiFi running at: https://$DOCKER_HOST:8443"
echo "provisioner for PiWiNiFi running at: https://$DOCKER_HOST:443"
