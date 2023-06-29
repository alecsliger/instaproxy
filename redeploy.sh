#!/bin/sh

## Please edit the parameters below before running this script
## Additional info can be found at https://github.com/alecsliger/instaproxy

############################################## PARAMETERS #####################################################
REGION=""
SSHIP=""
PUB_SSH_KEY=""
SUBSCRIPTIONID=""

## The 5 parameters below should work by default, assuming you run the script from the root directory of the project
PRE_TEMPLATEPATH="./Templates/template.json"
PRE_PARAMETERPATH="./Templates/parameters.json"
MAIN_TEMPLATEPATH="./Templates/flatcar.json"
MAIN_PARAMETERPATH="./Templates/flatcar.parameters.json"
BUTANEPATH="./butane.yml"
###############################################################################################################

## Prerequisite dependency deployment
pre_deploy_function () {
	## Create the Resource Group
	az group create -l $REGION -n ProxyRG

	## Create the Resources
	az deployment group create --name RGDeploy --resource-group ProxyRG --template-file $PRE_TEMPLATEPATH --parameters @$PRE_PARAMETERPATH

	## Uncomment the next two lines to disable the network watcher and remove the RG
	#az network watcher configure -g NetworkWatcherRG -l $REGION --enabled false
	#az group delete -n NetworkWatcherRG -y

	## Associate NSG to entire VNET and remove interface redundancy
	az network vnet subnet update -g ProxyRG -n default --vnet-name ProxyVNET --network-security-group ProxyVM-nsg
	az network nic update -g ProxyRG -n ProxyNIC --remove network_security_group

	## Add rule to NSG to allow SSH inbound from your IP
	az network nsg rule create -g ProxyRG --nsg-name ProxyVM-nsg -n AllowMyIpSSHInbound --priority 100 --source-address-prefixes $SSHIP --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol tcp --description "Allow my IP inbound on port 22 (SSH)"
}

## Main VM deployment
main_deploy_function () {
	# Deletes old VM (If applicable)
	az resource delete --resource-group ProxyRG --name ProxyVM --resource-type "Microsoft.Compute/virtualMachines"

	# Create new VM via JSON template files
	az deployment group create --name ProxyDeploy --resource-group ProxyRG --template-file $MAIN_TEMPLATEPATH --parameters @$MAIN_PARAMETERPATH

	# Associate old public IP with NIC after creation to maintain consistency
	az network nic ip-config update --name ipconfig1 --nic-name ProxyNIC --resource-group ProxyRG --public-ip-address ProxyVM-ip
}

## Region replacement function
region_replace () {
	sed -i '6s/.*/            "value": "'$REGION'"/' $MAIN_PARAMETERPATH
	sed -i '6s/.*/            "value": "'$REGION'"/' $PRE_PARAMETERPATH
}

## Butane YAML > ignition > base64 conversion function
ignition_function () {
	sudo cat $BUTANEPATH | sudo docker run --rm -i quay.io/coreos/butane:latest > ./ignition.json
	CUSTOM_DATA_VAR=$(base64 -w0 ./ignition.json)
	rm ./ignition.json
	sed -i '45s/.*/            "value": "'$CUSTOM_DATA_VAR'"/' $MAIN_PARAMETERPATH
}

## Public SSH key replace function
SSH_KEY_function () {
	SSH_LINE_VAR='            "value": "'$PUB_SSH_KEY'"'
	sed -i "42s|.*|$SSH_LINE_VAR|" $MAIN_PARAMETERPATH
}

## Update subsCription ID function
SUBSCRIPTIONID_function () {
	SUBID_LINEVAR='            "value": "/subscriptions/'$SUBSCRIPTIONID'/resourceGroups/ProxyRG/providers/Microsoft.Network/virtualNetworks/ProxyVNET"'
	sed -i "15s|.*|$SUBID_LINEVAR|" $MAIN_PARAMETERPATH
}

## Help function
help_function () {
	echo "Usage: $(basename $0) [-p] [-d] [-r] [-i] [-s] [-c] [-h]"
        echo "OPTIONS"
	echo "	-p	Runs pre-deployment operations to create the resource group and dependency devices. You should only need to run this once"
	echo ""
	echo "	-d	This option will destroy and reprovision your VM. This is a destructive operation, and any data not saved from your VM will be lost"
	echo ""
	echo "	-r	Apply the region variable in this script to both parameter files for deployment"
	echo ""
	echo "	-i	Regenerate the Igniton config from Butane.yml and append result to the main parameters 'custom data' field"
	echo ""
	echo "	-s	Apply the SSH key variable in this script to the main parameter file"
	echo ""
	echo "	-c 	Apply Azure subscription ID variable from this script to the main parameter file"
	echo ""
	echo "	-h	Show this menu"
	echo ""
}

## Option handling
while getopts "pdhrisc" OPTION; do
	case $OPTION in
	p)
		pre_deploy_function
		;;
	d)
		main_deploy_function
		;;
	h)
                help_function
		;;
	r)
		region_replace
		;;
	i)
		ignition_function
		;;
	s)
		SSH_KEY_function
		;;
	c)
		SUBSCRIPTIONID_function
		;;
	?)
		echo "Usage: $(basename $0) [-p] [-d] [-r] [-i] [-s] [-c] [-h]"
                exit 1
		;;
	esac
done

## If no option appended, show help & exit
if [ $# -eq 0 ];
then
	help_function
    	exit 1
else
	exit 0
fi
