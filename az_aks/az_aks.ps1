# Create an Azure Kubernetes Service (AKS) cluster that uses availability zones
# https://docs.microsoft.com/en-us/azure/aks/availability-zones
<# An AKS cluster distributes resources such as nodes and storage across logical sections of underlying Azure infrastructure. 
This deployment model when using availability zones, ensures nodes in a given availability zone are physically separated from those defined in another availability zone. 
AKS clusters deployed with multiple availability zones configured across a cluster provide a higher level of availability to protect against a hardware failure or a planned maintenance event.
By defining node pools in a cluster to span multiple zones, nodes in a given node pool are able to continue operating even if a single zone has gone down. 
Your applications can continue to be available even if there is a physical failure in a single datacenter if orchestrated to tolerate failure of a subset of nodes.
#>
# Requires Azure CLI version 2.0.76 or later installed and configured. Run az --version to find the version.
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
# https://docs.microsoft.com/en-us/azure/aks/availability-zones#limitations-and-region-availability

$location = "australiaeast"
$aksrg = "az-aks-rg"
$aksclustername = "azdemo-aue-aks"

# Create an AKS cluster across availability zones
az group create --name $aksrg --location $location
az aks create --resource-group $aksrg --name $aksclustername --generate-ssh-keys --vm-set-type VirtualMachineScaleSets --load-balancer-sku standard --node-count 3 --zones 1 2 3

# Verify node distribution across zones
az aks get-credentials --resource-group $aksrg --name $aksclustername

# Verify pod distribution across zones
az aks scale --resource-group $aksrg --name $aksclustername --node-count 5

# cleanup
# az group delete -n $aksrg