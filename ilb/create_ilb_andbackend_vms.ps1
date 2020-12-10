# https://docs.microsoft.com/en-gb/azure/load-balancer/quickstart-load-balancer-standard-internal-cli?tabs=option-1-create-load-balancer-standard
# iLB Quickstart with cli and ubuntu

$location = "australiaeast"
$rg = "spoke3-vnet-rg"
$nsg = "ilb-nsg"
$nsgrule = "rulehttp"
$workloadvnet = "spoke3-vnet"
$addressspace = "10.5.0.0/16"
$workloadsubnetspace = "10.5.1.0/24"
$workloadsubnet = "workload"
$lb = "roost"
$vm1 = "Burnout"
$vm1nic = $vm1 + "-nic"
$vm2 = "Blowout"
$vm2nic = $vm2 + "-nic"

# rg
az group create --name $rg --location $location

# vnet
az network vnet create --resource-group $rg --location $location --name $workloadvnet --address-prefixes $addressspace --subnet-name $workloadsubnet --subnet-prefixes $workloadsubnetspace

# nsg
az network nsg create --resource-group $rg --name $nsg

# nsg rule - inbound
az network nsg rule create --resource-group $rg --nsg-name $nsg --name $nsgrule --protocol '*' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow --priority 200

# backend vms
# nics, with DNS
az network nic create --resource-group $rg --name $vm1nic --vnet-name $workloadvnet --subnet $workloadsubnet --network-security-group $nsg
az network nic create --resource-group $rg --name $vm2nic --vnet-name $workloadvnet --subnet $workloadsubnet --network-security-group $nsg
# vms in different zones
# az vm create --resource-group $rg --name $vm1 --nics $vm1nic --image UbuntuLTS --admin-user azureuser --generate-ssh-keys --custom-data cloud-init.txt --zone 1 --no-wait #ssh-keys
# az vm create --resource-group $rg --name $vm2 --nics $vm2nic --image UbuntuLTS --admin-user azureuser --generate-ssh-keys --custom-data cloud-init.txt --zone 2 --no-wait #ssh-keys
az vm create --resource-group $rg --name $vm1 --nics $vm1nic --image UbuntuLTS --admin-user <user> --admin-password <password> --custom-data cloud-init.txt --zone 1 --no-wait
az vm create --resource-group $rg --name $vm2 --nics $vm2nic --image UbuntuLTS --admin-user <user> --admin-password <password> --custom-data cloud-init.txt --zone 2 --no-wait

# std load balancer
az network lb create --resource-group $rg --name $lb --sku Standard --vnet-name $workloadvnet --subnet $workloadsubnet --frontend-ip-name FrontEndIP --backend-pool-name BackEndPool
# lb health probe
az network lb probe create --resource-group $rg --lb-name $lb --name HealthProbe --protocol tcp --port 80
# lb rule
az network lb rule create --resource-group $rg --lb-name $lb --name lbhttprule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name FrontEndIP --backend-pool-name BackEndPool --probe-name HealthProbe --disable-outbound-snat true --idle-timeout 15 --enable-tcp-reset true

# Note: create peering for bastion if required.

<# **************************************
Note
Test internet access from machines at this point i.e. before adding VMs to iLB backend.
Connect to VM(s) via Bastion. Note: ssh keys are at C:\Users\<username>\.ssh
Test internet from cmdline, i.e. http 200 response
curl -I http://www.google.com

[google dns]
[ping -c 2 8.8.8.8]
[ping -a blowout]
[check version:]
[cat /etc/issue]

[curl ipinfo.io/ip should return an IP address.]
***************************************** #>

# add vms to lb backend

az network nic ip-config address-pool add --address-pool BackendPool --ip-config-name ipconfig1 --nic-name $vm1nic --resource-group $rg --lb-name $lb
az network nic ip-config address-pool add --address-pool BackendPool --ip-config-name ipconfig1 --nic-name $vm2nic --resource-group $rg --lb-name $lb

<# **************************************
Note
Retest internet access from machines at this point i.e. after adding VMs to iLB backend.
Connect to VM(s) via Bastion. Note: ssh keys are at C:\Users\<username>\.ssh
Test internet from cmdline, i.e. http 200 response
curl -I http://www.google.com

[google dns]
[ping -c 2 8.8.8.8]
[ping -a blowout]
[check version:]
[cat /etc/issue]
[curl ipinfo.io/ip should not return an IP address.]
***************************************** #>

# test lb
# from a machine that can connect to iLB on private network, open http://10.5.1.6 in a browser. This is the iLB frontend IP.
# https://docs.microsoft.com/en-gb/azure/load-balancer/quickstart-load-balancer-standard-internal-cli?tabs=option-1-create-load-balancer-standard#test

# cleanup
# az group delete --name $rg