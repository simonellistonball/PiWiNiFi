#!/bin/sh

azure group create sballHadoopInfrastructureWest --location westus
azure group create sballHadoopMachinesWest --location westus

azure group deployment create -e azure-params-small.json -f azure-template-infra.json sballHadoopInfrastructureWest version1
azure group deployment create -e azure-params-small.json -f azure-template-small.json sballHadoopMachinesWest version1
