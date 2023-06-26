#!/bin/sh

## A script to delete and redeploy your Proxy stack using az-cli with provided ARM template and parameter file
## If you changed the names of resources, remember to update the script accordingly
## UPDATE FILE PATHS HERE FIRST ##
TEMPLATEPATH="./flatcar.json"
PARAMETERPATH="./flatcar.parameters.json"


# Deletes old VM (If applicable)
az resource delete --resource-group ProxyRG --name ProxyVM --resource-type "Microsoft.Compute/virtualMachines"

# Create new VM via JSON template files
az deployment group create \
  --name ProxyDeploy \
  --resource-group ProxyRG \
  --template-file $TEMPLATEPATH \
  --parameters @$PARAMETERPATH

# Associate old public IP with NIC after creation to maintain consistency
az network nic ip-config update --name ipconfig1 --nic-name ProxyNIC --resource-group ProxyRG --public-ip-address ProxyVM-ip
