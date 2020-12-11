# https://docs.microsoft.com/en-us/azure/api-management/get-started-create-service-instance-cli
# Quickstart: Create a new Azure API Management service instance by using the Azure CLI (preview)

$apimrg = "apim-rg"
$location = "australiaeast"
$apimname = "borgapim"
$pubname = "Contoso"
$pubmail = "admin@contoso.com"

# rg
az group create --name $apimrg --location $location
# apim service
az apim create --name $apimname  --resource-group $apimrg --publisher-name $pubname --publisher-email $pubmail --no-wait
# By default, the command creates the instance in the Developer tier, an economical option to evaluate Azure API Management. This tier isn't for production use.
# It can take 30-40 minutes to create and activate an API Management service in this tier. The previous command uses the --no-wait option so that the command returns immediately while the service is created.

# check status
# az apim show --name $apimname --resource-group $apimrg --output table

# cleanup
# az group delete --name $apimrg

# import and publish an API
# https://docs.microsoft.com/en-us/azure/api-management/import-and-publish