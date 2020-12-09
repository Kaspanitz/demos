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

$workloadvnet = "spoke3-vnet"
$workloadsubnet = "workload"
$workloadsubnetspace = "10.5.1.0/24"
$workloadrg = "spoke3-vnet-rg"
$subscription = "..."
$workloadvnetrid = "/subscriptions/$subscription/resourceGroups/$workloadrg/providers/Microsoft.Network/virtualNetworks/$workloadvnet"

# rg
az group create --name $fwrg --location $location
# vnet
az network vnet create --name $fwvnet --resource-group $fwrg --location $location --address-prefix $addressspace --subnet-name $fwsubnet --subnet-prefix $fwsubnetspace
# using existing subnets instead
#az network vnet subnet create --name Workload-SN --resource-group $fwrg --vnet-name $fwvnet --address-prefix 10.0.2.0/24
#az network vnet subnet create --name Jump-SN --resource-group $fwrg --vnet-name $fwvnet --address-prefix 10.0.3.0/24

# fw
az network firewall create --name $fw --resource-group $fwrg --location $location
az network public-ip create --name $fwpip --resource-group $fwrg --location $location --allocation-method static --sku $fwsku
az network firewall ip-config create --firewall-name $fw --name fw-config --public-ip-address $fwpip --resource-group $fwrg --vnet-name $fwvnet
az network firewall update --name $fw --resource-group $fwrg 
az network public-ip show --name $fwpip --resource-group $fwrg
# Note the private IP address
$fwprivaddr="$(az network firewall ip-config list -g $fwrg -f $fw --query "[?name=='fw-config'].privateIpAddress" --output tsv)"

# default route 
# table with bgp route propagation disabled - must exist in same rg as vnet hosting subnets that it will be associated with
az network route-table create --name firewall-rt --resource-group $workloadrg --location $location --disable-bgp-route-propagation true
# route
az network route-table route create --resource-group $workloadrg --name dg-route --route-table-name firewall-rt --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $fwprivaddr

# associate route table to desired workload subnet
az network vnet subnet update -n $workloadsubnet -g $workloadrg --vnet-name $workloadvnet --address-prefixes $workloadsubnetspace --route-table firewall-rt

# fw app rule
az network firewall application-rule create --collection-name App-Coll01 --firewall-name $fw --name Allow-Google --protocols Http=80 Https=443 --resource-group $fwrg --target-fqdns www.google.com --source-addresses $workloadsubnetspace --priority 200 --action Allow
# fw network rule
az network firewall network-rule create --collection-name Net-Coll01 --destination-addresses 209.244.0.3 209.244.0.4 --destination-ports 53 --firewall-name $fw --name Allow-DNS --protocols UDP --resource-group $fwrg --priority 200 --source-addresses $workloadsubnetspace --action Allow

# peer workload vnet and firewall vnet ISSUES here (had to do manual - check peering as one side (fw) was stuck on initiated...)
az network vnet peering create -g $fwrg -n fwtospoke3 --vnet-name $fwvnet --remote-vnet $workloadvnetrid --allow-vnet-access

# test firewall by looking up and navigating to www.google.com from a VM on the workload subnet

# clean up
# az group delete -n $fwrg