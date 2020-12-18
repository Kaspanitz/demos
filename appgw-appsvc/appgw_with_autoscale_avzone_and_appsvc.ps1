# https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-autoscale-ps
# autoscale and availability zone deployment
# script requires PKIClient module, Certificate Provider
# variables
$subName = "<sub name here>"
$rg = "appgw-rg"
$appName = "borg-wa"
$location = "australiaeast"
$vnetName = "borg-vnet"
$appServicePlan = "borg-asp"
$appGatewayName = "borg-ag"

# Connect-AzAccount
# Select-AzSubscription -Subscription $subName

# rg
New-AzResourceGroup -Name $rg -Location $location

# Create a self-signed certificate
New-SelfSignedCertificate `
-certstorelocation cert:\localmachine\my `
-dnsname www.contoso.com

$passwd = ConvertTo-SecureString -String "Azure123456!" -Force -AsPlainText

# *************************************************************
# note: use thumbprint from New-SelfSignedCertificate command *
# *************************************************************

$thumb = (dir cert:\localmachine\my | where{$_.subject -like "*www.contoso.com*"}).thumbprint

Export-PfxCertificate `
-cert cert:\localMachine\my\$thumb `
-FilePath c:\appgwcert.pfx `
-Password $passwd

# Create VNet with two subnets
# Create a virtual network with one dedicated subnet for an autoscaling application gateway. Currently only one autoscaling application gateway can be deployed in each dedicated subnet.
$sub1 = New-AzVirtualNetworkSubnetConfig -Name "AppGwSubnet" -AddressPrefix "10.3.1.0/24"
$sub2 = New-AzVirtualNetworkSubnetConfig -Name "BackendSubnet" -AddressPrefix "10.3.2.0/24"
$vnet = New-AzvirtualNetwork -Name $vnetName -ResourceGroupName $rg `
-Location $location -AddressPrefix "10.3.0.0/16" -Subnet $sub1, $sub2

# Create a reserved public IP
# Specify the allocation method of PublicIPAddress as Static. An autoscaling application gateway VIP can only be static. Dynamic IPs are not supported. Only the standard PublicIpAddress SKU is supported.
# Create static public IP
$pip = New-AzPublicIpAddress -ResourceGroupName $rg -name "AppGwVIP" `
-location $location -AllocationMethod Static -Sku Standard

# Retrieve details of the resource group, subnet, and IP in a local object to create the IP configuration details for the application gateway.
$resourceGroup = Get-AzResourceGroup -Name $rg
$publicip = Get-AzPublicIpAddress -ResourceGroupName $rg -name "AppGwVIP"
$vnet = Get-AzvirtualNetwork -Name $vnetName -ResourceGroupName $rg
$gwSubnet = Get-AzVirtualNetworkSubnetConfig -Name "AppGwSubnet" -VirtualNetwork $vnet

#Configure the infrastructure
# Configure the IP config, front-end IP config, back-end pool, HTTP settings, certificate, port, listener, and rule in an identical format to the existing Standard application gateway. The new SKU follows the same object model as the Standard SKU.
$ipconfig = New-AzApplicationGatewayIPConfiguration -Name "IPConfig" -Subnet $gwSubnet
$fip = New-AzApplicationGatewayFrontendIPConfig -Name "FrontendIPCOnfig" -PublicIPAddress $publicip
$pool = New-AzApplicationGatewayBackendAddressPool -Name "Pool1" `
       -BackendIPAddresses testbackend1.westus.cloudapp.azure.com, testbackend2.westus.cloudapp.azure.com
$fp01 = New-AzApplicationGatewayFrontendPort -Name "SSLPort" -Port 443
$fp02 = New-AzApplicationGatewayFrontendPort -Name "HTTPPort" -Port 80

$securepfxpwd = ConvertTo-SecureString -String "Azure123456!" -AsPlainText -Force
$sslCert01 = New-AzApplicationGatewaySslCertificate -Name "SSLCert" -Password $securepfxpwd `
            -CertificateFile "c:\appgwcert.pfx"
$listener01 = New-AzApplicationGatewayHttpListener -Name "SSLListener" `
             -Protocol Https -FrontendIPConfiguration $fip -FrontendPort $fp01 -SslCertificate $sslCert01
$listener02 = New-AzApplicationGatewayHttpListener -Name "HTTPListener" `
             -Protocol Http -FrontendIPConfiguration $fip -FrontendPort $fp02

$setting = New-AzApplicationGatewayBackendHttpSettings -Name "BackendHttpSetting1" `
          -Port 80 -Protocol Http -CookieBasedAffinity Disabled
$rule01 = New-AzApplicationGatewayRequestRoutingRule -Name "Rule1" -RuleType basic `
         -BackendHttpSettings $setting -HttpListener $listener01 -BackendAddressPool $pool
$rule02 = New-AzApplicationGatewayRequestRoutingRule -Name "Rule2" -RuleType basic `
         -BackendHttpSettings $setting -HttpListener $listener02 -BackendAddressPool $pool

# Specify autoscale
# Now you can specify the autoscale configuration for the application gateway. Two autoscaling configuration types are supported:
# 1. Fixed capacity mode. In this mode, the application gateway does not autoscale and operates at a fixed Scale Unit capacity.
# $sku = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 2
# 2. Autoscaling mode. In this mode, the application gateway autoscales based on the application traffic pattern.
$autoscaleConfig = New-AzApplicationGatewayAutoscaleConfiguration -MinCapacity 2
$sku = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2

# Create the application gateway and include redundancy zones and the autoscale configuration.
$appgw = New-AzApplicationGateway -Name "AutoscalingAppGw" -Zone 1,2,3 `
  -ResourceGroupName $rg -Location $location -BackendAddressPools $pool `
  -BackendHttpSettingsCollection $setting -GatewayIpConfigurations $ipconfig `
  -FrontendIpConfigurations $fip -FrontendPorts $fp01, $fp02 `
  -HttpListeners $listener01, $listener02 -RequestRoutingRules $rule01, $rule02 `
  -Sku $sku -sslCertificates $sslCert01 -AutoscaleConfiguration $autoscaleConfig

  # Test the application gateway
  Get-AzPublicIPAddress -ResourceGroupName $rg -Name AppGwVIP

  # Cleanup
  # Remove-AzResourceGroup -Name $rg
