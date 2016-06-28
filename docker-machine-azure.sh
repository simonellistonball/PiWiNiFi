docker-machine create piwinificloud \
  --driver azure \
  --azure-subscription-id 7d204bd6-841e-43fb-8638-c5eedf2ea797 \
  --azure-resource-group sballHadoopMachines \
  --azure-size A3 \
  --azure-location northeurope \
  --azure-vnet hadoopVnet \
  --azure-subnet hadoopSubnet \
  --azure-subnet-prefix 10.0.0.0/24 \
  --azure-private-ip-address 10.0.0.100 \
  --azure-open-port 8443 \
  --azure-open-port 8444 \
  --azure-open-port 443

eval $(docker-machine env piwinificloud)

# copy the relevant volumes to the docker-machine
docker-machine scp -r nifi/conf /data/cloud/
docker-machine scp -r nifi/certs /data/cloud/
docker-machine scp -r nifi/custom /data/cloud/

docker-machine scp -r provisioner/certs /data/provisioner/
docker-machine scp -r provisioner/data /data/provisioner/
