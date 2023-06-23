#!/bin/sh
## This script will create the prerequisite group and resources necessary to deploy the VM

## Update the region variable below to match the main arm template (Default=eastus), and the paths to the ARM files
## The fourth variable is for your IP address to allow SSH
REGION="eastus2"
TEMPLATEPATH="~/RG-Deploy/template.json"
PARAMETERPATH="~/RG-Deploy/parameters.json"
SSHIP="1.2.3.4"

# Create RG
az group create -l $REGION -n ProxyRG

# Create Resources
az deployment group create \
  --name RGDeploy \
  --resource-group ProxyRG \
  --template-file $TEMPLATEPATH \
  --parameters @$PARAMETERPATH

## Uncomment the next two lines to disable the network watcher and remove the RG
#az network watcher configure -g NetworkWatcherRG -l $REGION --enabled false
#az group delete -n NetworkWatcherRG -y

# Associate NSG to entire VNET and remove interface redundancy
az network vnet subnet update -g ProxyRG -n default --vnet-name ProxyVNET --network-security-group ProxyVM-nsg
az network nic update -g ProxyRG -n ProxyNIC --remove network_security_group

# Add rule to NSG to allow SSH inbound from your IP
az network nsg rule create -g ProxyRG --nsg-name ProxyVM-nsg -n AllowMyIpSSHInbound --priority 100 --source-address-prefixes $SSHIP --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol tcp --description "Allow my IP inbound on port 22 (SSH)"
