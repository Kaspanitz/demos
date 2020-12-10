# Quickstart: Create a NAT gateway - ARM template
# https://docs.microsoft.com/en-us/azure/virtual-network/quickstart-create-nat-gateway-template

$context = Get-AzSubscription -SubscriptionId ....
Set-AzContext $context

$rgName = "spoke3-vnet-rg" 
$rgLocation = "australiaeast"

# New-AzResourceGroup -ResourceGroupName $rgName -Location $rgLocation
New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile .\natgateway_subnet_array.json -Verbose -Name "natgw-test"