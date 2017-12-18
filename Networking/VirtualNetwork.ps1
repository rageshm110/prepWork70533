Clear-Host
Login-AzureRmAccount
$subscriptionName = 'Developer Program Benefit'
$availableSubscriptions = Get-AzureRmSubscription
$reqSubscription = $availableSubscriptions | Where-Object {$_.Name -eq 'Developer Program Benefit'}
Select-AzureRmSubscription -SubscriptionObject $reqSubscription

$rgName = 'Demo'
$rgLocation = 'eastus2'
New-AzureRmResourceGroup -Name $rgName -Location $rgLocation


# Create virtual network
$vnName = '{0}_{1}_VN' -f $rgName, $rgLocation
New-AzureRmVirtualNetwork -Name $vnName -ResourceGroupName $rgName -Location $rgLocation -AddressPrefix 10.0.0.0/24

$vnObj = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnName
#Remove-AzureRmResourceGroup -Name $rgName

#Create NSG
$NSGName = "{0}_NSG" -f $vnObj.Name
$vnNSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $rgName -Location $rgLocation
# create subnet
$subNetName = "{0}_Subnet1" -f $vnObj.Name
$subNet1 = New-AzureRmVirtualNetworkSubnetConfig -Name $subNetName -AddressPrefix 10.0.0.0/25 -NetworkSecurityGroup $vnNSG
$subNetName = "{0}_Subnet2" -f $vnObj.Name
$subNet2 = New-AzureRmVirtualNetworkSubnetConfig -Name $subNetName -AddressPrefix 10.0.0.128/25 -NetworkSecurityGroup $vnNSG
$vnObj.Subnets.Clear()
$vnObj.Subnets.Add($subNet1)
$vnObj.Subnets.Add($subNet2)
$vnObj | Set-AzureRmVirtualNetwork