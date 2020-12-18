# script requires minimum Azure CLI version 2.0.74
# variables
$resourceGroupName="appgwappsvc-rg"
$appName="webappwithgateway"
$location="Australia East"

# rg
az group create --name $resourceGroupName --location $location

# network resources
az network vnet create --resource-group $resourceGroupName --name myVNet --location $location --address-prefix 10.3.0.0/16 --subnet-name myAGSubnet --subnet-prefix 10.3.1.0/24
az network public-ip create --resource-group $resourceGroupName --location $location --name myAGPublicIPAddress --dns-name $appName --sku Standard

# app service plan
az appservice plan create --resource-group $resourceGroupName --name myAppServicePlan --location $location --sku S1

# web app
az webapp create --resource-group $resourceGroupName --name $appName --plan myAppServicePlan
$appFqdn=$(az webapp show --name $appName --resource-group $resourceGroupName --query defaultHostName -o tsv)

# app gateway
az network application-gateway create --resource-group $resourceGroupName --name myAppGateway --location $location --vnet-name myVNet `
--subnet myAGsubnet --min-capacity 2 --sku Standard_v2 --http-settings-cookie-based-affinity Disabled --frontend-port 80 `
--http-settings-port 80 --http-settings-protocol Http --public-ip-address myAGPublicIPAddress --servers $appFqdn

az network application-gateway http-settings update --resource-group $resourceGroupName --gateway-name myAppGateway --name appGatewayBackendHttpSettings --host-name-from-backend-pool

# Apply Access Restriction to Web App
az webapp config access-restriction add --resource-group $resourceGroupName --name $appName --priority 200 --rule-name gateway-access --subnet myAGSubnet --vnet-name myVNet

# Get the App Gateway Fqdn
az network public-ip show --resource-group $resourceGroupName --name myAGPublicIPAddress --query {$AppGatewayFqdn:dnsSettings.fqdn} --output table

# cleanup
# az group delete -n $resourceGroupName