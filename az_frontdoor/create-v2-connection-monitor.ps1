. ./_vars.ps1

<#
az network watcher connection-monitor create --name "$app-nofd" --endpoint-source-name "$vm1" `
--endpoint-source-resource-id "/subscriptions/$sub/resourceGroups/$vm1rg/providers/Microsoft.Compute/virtualMachines/$vm1" `
--endpoint-dest-name "no-fd-web-test" --endpoint-dest-address "https://$app.azurewebsites.net" --test-config-name TCPTestConfig --protocol Tcp --tcp-port 443

az network watcher connection-monitor create --name "$app-fd"  --endpoint-source-name "$vm1" `
--endpoint-source-resource-id "/subscriptions/$sub/resourceGroups/$vm1rg/providers/Microsoft.Compute/virtualMachines/$vm1" `
--endpoint-dest-name "fd-web-test" --endpoint-dest-address "https://$frontDoor.azurefd.net" --test-config-name TCPTestConfig --protocol Tcp --tcp-port 443


az network watcher connection-monitor create --name "$vm2-nofd" --endpoint-source-name "$vm2" `
--endpoint-source-resource-id "/subscriptions/$sub/resourceGroups/$vm2rg/providers/Microsoft.Compute/virtualMachines/$vm2" `
--endpoint-dest-name "no-fd-web-test" --endpoint-dest-address "http://jvappmod-sea.azurewebsites.net/" --test-config-name HTTPTestConfig --protocol http --tcp-port 80

az network watcher connection-monitor create --name "$vm2-fd"  --endpoint-source-name "$vm2" `
--endpoint-source-resource-id "/subscriptions/$sub/resourceGroups/$vm2rg/providers/Microsoft.Compute/virtualMachines/$vm2" `
--endpoint-dest-name "fd-web-test" --endpoint-dest-address "http://jvappmod.azurefd.net/" --test-config-name HTTPTestConfig --protocol http --tcp-port 80

az network watcher connection-monitor create --name "$vm2-nofd" --endpoint-source-name "$onpremagent" `
--endpoint-source-resource-id "/subscriptions/$sub/resourceGroups/$vm2rg/providers/Microsoft.Compute/virtualMachines/$vm2" `
--endpoint-dest-name "no-fd-web-test" --endpoint-dest-address "http://jvappmod-sea.azurewebsites.net/" --test-config-name HTTPTestConfig --protocol http --tcp-port 80

az network watcher connection-monitor create --name "$vm2-fd"  --endpoint-source-name "$onpremagent" `
--endpoint-source-resource-id "/subscriptions/$sub/resourceGroups/$vm2rg/providers/Microsoft.Compute/virtualMachines/$vm2" `
--endpoint-dest-name "fd-web-test" --endpoint-dest-address "http://jvappmod.azurefd.net/" --test-config-name HTTPTestConfig --protocol http --tcp-port 80
#>

<#
$wid = "/subscriptions/$sub/resourcegroups/hub-vnet-rg/providers/microsoft.operationalinsights/workspaces/$laws"
$urls =@("http://jvappmod-sea.azurewebsites.net/", "http://jvappmod.azurefd.net/")

foreach ($url in $urls)
{
az network watcher connection-monitor create `
--name "$onpremagent-nofd-cli-v1" `
--endpoint-source-name "$onpremagent-nofd" `
--endpoint-source-resource-id $wid `
--endpoint-source-address $onpremagent `
--endpoint-source-type "MMAWorkspaceMachine" `
--endpoint-dest-name "nofd" `
--endpoint-dest-address $direct `
--endpoint-dest-type "ExternalAddress" `
--test-config-name httptest `
--protocol http `
--http-method Get `
--http-port 80 `
--frequency 1800 `
--output-type "Workspace" `
--workspace-ids $wid
}
#>

$wid = "/subscriptions/$sub/resourcegroups/$lawsrg/providers/microsoft.operationalinsights/workspaces/$laws"
$direct = "http://jvappmod-sea.azurewebsites.net/"
$fd = "http://jvappmod.azurefd.net/"

# on-prem agent, no fd
az network watcher connection-monitor create `
--name "$onpremagent-nofd-cli-v1" `
--endpoint-source-name "$onpremagent-nofd" `
--endpoint-source-resource-id $wid `
--endpoint-source-address $onpremagent `
--endpoint-source-type "MMAWorkspaceMachine" `
--endpoint-dest-name "nofd" `
--endpoint-dest-address $direct `
--endpoint-dest-type "ExternalAddress" `
--test-config-name httptest `
--protocol http `
--http-method Get `
--http-port 80 `
--frequency 1800 `
--output-type "Workspace" `
--workspace-ids $wid

# on-prem agent, fd
az network watcher connection-monitor create `
--name "$onpremagent-fd-cli-v1" `
--endpoint-source-name "$onpremagent-fd" `
--endpoint-source-resource-id $wid `
--endpoint-source-address $onpremagent `
--endpoint-source-type "MMAWorkspaceMachine" `
--endpoint-dest-name "fd" `
--endpoint-dest-address $fd `
--endpoint-dest-type "ExternalAddress" `
--test-config-name httptest `
--protocol http `
--http-method Get `
--http-port 80 `
--frequency 1800 `
--output-type "Workspace" `
--workspace-ids $wid

# az network watcher connection-monitor --help

# $rid_az = "/subscriptions/$sub/resourceGroups/$vm2rg/providers/Microsoft.Compute/virtualMachines/$vm2"