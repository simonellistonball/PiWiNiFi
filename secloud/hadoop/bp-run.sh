#!/bin/bash

address="http://piwinifi.westus.cloudapp.azure.com:8080/api/v1"

curl -w "%{http_code}" -u admin:admin -H "X-Requested-By: simon" -d @blueprint.json -X POST $address/blueprints/piwinifi #&& \
curl -u admin:admin -H "X-Requested-By: simon" -d @hosts.json -X POST $address/clusters/piwinifi
