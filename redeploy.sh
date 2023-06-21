#!/bin/sh

## A script to delete and redeploy your Proxy stack using az-cli with provided ARM template and parameter file
## If you changed the names of resources, remember to update the script accordingly
## UPDATE FILE PATHS FIRST ##

# Deletes old VM (If applicable)
az resource delete --resource-group ProxyRG --name ProxyVM --resource-type "Microsoft.Compute/virtualMachines"

# Create new VM via JSON template files
az deployment group create \
  --name ProxyDeploy \
  --resource-group ProxyRG \
  ## CHANGE PATHS HERE!! ## 
  --template-file "~/PATH-TO-TEMPLATE-FILE/flatcar.json" \
  --parameters '@~/PATH-TO-PARAMETER-FILE/flatcar.parameters.json'

# Associate old public IP with NIC after creation to maintain consistency
az network nic ip-config update --name ipconfig1 --nic-name ProxyNIC --resource-group ProxyRG --public-ip-address ProxyVM-ip
