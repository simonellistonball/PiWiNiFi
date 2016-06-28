#!/bin/sh

GATEWAY=piwinifi.westus.cloudapp.azure.com
scp -i id_azure id_azure piwinifi.westus.cloudapp.azure.com:~/.ssh/id_azure
scp -i id_azure -r gateway piwinifi.westus.cloudapp.azure.com:~

ssh -tt -i id_azure piwinifi.westus.cloudapp.azure.com "chmod a+x gateway/*.sh && gateway/bootstrap.sh"
