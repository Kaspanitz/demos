# https://docs.microsoft.com/en-us/azure/firewall/deploy-cli#:~:text=%20Deploy%20and%20configure%20Azure%20Firewall%20using%20Azure,outbound...%206%20Clean%20up%20resources.%20%20More%20
# Deploy and configure Azure Firewall Standard using Azure CLI
# variables
$location = "australiaeast"
$fwrg = "firewall-rg"
$fwvnet = "firewall-vnet"
$addressspace = "10.6.0.0/16"
$fwsubnetspace = "10.6.1.0/26"
$fwsubnet = "AzureFirewallSubnet"
$fw = "firewall"
$fwsku = "standard"
$fwpip = "fw-pip"

# rg
az group create --name $fwrg --location $location
# vnet
az network vnet create --name $fwvnet --resource-group $fwrg --location $location --address-prefix $addressspace --subnet-name $fwsubnet --subnet-prefix $fwsubnetspace
# using existing subnets instead
#az network vnet subnet create --name Workload-SN --resource-group $fwrg --vnet-name $fwvnet --address-prefix 10.0.2.0/24
#az network vnet subnet create --name Jump-SN --resource-group $fwrg --vnet-name $fwvnet --address-prefix 10.0.3.0/24

# fw
az network firewall create --name $fw --resource-group $fwrg --location $location --zones 1
az network public-ip create --name $fwpip --resource-group $fwrg --location $location --allocation-method static --sku $fwsku
az network firewall ip-config create --firewall-name $fw --name fw-config --public-ip-address $fwpip --resource-group $fwrg --vnet-name $fwvnet
az network firewall update --name $fw --resource-group $fwrg 
az network public-ip show --name $fwpip --resource-group $fwrg

# clean up
# az group delete -n $fwrg