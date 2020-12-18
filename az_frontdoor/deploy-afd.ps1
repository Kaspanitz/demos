. ./_vars.ps1

az account set --subscription $subname
$frontDoor = 'jvappmod'

az network front-door create -n $frontDoor -g $rg --tags $tags `
    --backend-address "$app.azurewebsites.net" `
    --accepted-protocols Http Https `
    --protocol Http

az network front-door routing-rule update --front-door-name $frontDoor -n 'DefaultRoutingRule' -g $rg `
    --caching 'Enabled'

start "https://$frontDoor.azurefd.net"