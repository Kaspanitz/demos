# https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-prevent
# link to metrics explorer:
# Check the public access setting for multiple accounts
# Add the Resource Graph extension to the Azure CLI environment
az extension add --name resource-graph
# Check the extension list (note that you may have other extensions installed)
# az extension list
# Run help for graph query options
# az graph query -h
$query = "resources | where type =~ 'Microsoft.Storage/storageAccounts' | extend allowBlobPublicAccess = parse_json(properties).allowBlobPublicAccess | project subscriptionId, resourceGroup, name, allowBlobPublicAccess"
# Login first with az login if not using Cloud Shell
# Run Azure Resource Graph query
az graph query -q $query
# Generate public access test
$sa = "<sa name here>"
$url = "https://$sa.blob.core.windows.net/`$logs" #"<absolute-url-to-blob>"
$url2 = "https://$sa.blob.core.windows.net/accesstest" #"<absolute-url-to-blob>"
$downloadTo = ($env:TEMP) #"<file-path-for-download>"
1..200 | %{Invoke-WebRequest -Uri $url -OutFile $downloadTo -ErrorAction Stop}

# Retrive file from SA using access key via PS1
$StorageAccountName = $sa
$StorageAccountKey = "<account key here>"
$ContainerName = "accesstest"
$Blob1Name = "accesstestfile.txt"
$TargetFolderPath = ($env:TEMP)

$context = New-AzStorageContext `
-StorageAccountName $StorageAccountName `
-StorageAccountKey $StorageAccountKey

$result = Get-AzStorageBlobContent `
-Blob $Blob1Name `
-Container $ContainerName `
-Context $context `
-Destination $TargetFolderPath

dir $TargetFolderPath access*.*   

# Anonymous Context
$context = New-AzStorageContext -StorageAccountName $StorageAccountName -Anonymous -Protocol "https"

$result = Get-AzStorageBlobContent `
-Blob $Blob1Name `
-Container $ContainerName `
-Context $context `
-Destination $TargetFolderPath

dir $TargetFolderPath access*.*