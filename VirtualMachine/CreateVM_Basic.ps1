Import-Module AzureRM.Compute
Import-Module AzureRM

Clear-Host
# rg = resource group
# vm = virtual machine

# login to azure
#$azureLoginAccount = Add-AzureRmAccount -Credential (Get-Credential -Message 'Azure login credential.' -UserName '')
Login-AzureRmAccount -Subscription 'Developer Program Benefit'
# Non-interatcive using microsoft live account is disabled.

# Basic information required for configuring VM
$rgName = 'Azure70533'
$rgLocation = 'westus2'
$azureLocations = Get-AzureRmLocation
if ($azureLocations.location -contains $rgLocation)
    {
        Write-Host '>>>>> Creating resource group <<<<<'
        New-AzureRmResourceGroup -Name $rgName -Location $rgLocation # Can store the result into a variable
        # create storage account
        $storeAccName = ("{0}DiskStore" -f $rgName).ToLower()
        #check storage account name availabilty
        $storageNameCheck  = Get-AzureRmStorageAccountNameAvailability -Name $storeAccName
        if ($storageNameCheck.NameAvailable -eq 'True')
        {
            Write-host ">>>>> Creating new storage account <<<<<" -ForegroundColor Yellow
            $storeAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $storeAccName -SkuName 'Standard_LRS' -Kind 'Storage' -Location $rgLocation
            ######################################################################################################
            # Network configuration
            $subnetName = $rgName + 'vmSubnet';
            $ipName = $rgName + 'vmIPAddr'
            $vnetName = $rgName + 'vmVirtualNetwork'
            $vmNicName = $rgName + 'vmNic'

            $vmSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'Azure70533vmSubNet' -AddressPrefix 10.0.0.0/24
            $vmPublicIP = New-AzureRmPublicIpAddress -Name 'Azure70533vmIPAddr' -ResourceGroupName $rgName -Location $rgLocation -AllocationMethod Dynamic # there gonna be modification to output object
            $vmVnet = New-AzureRMVirtualNetWork -Name $vnetName -ResourceGroupName $rgName -Location $rgLocation -AddressPrefix 10.0.0.0/16 -Subnet $vmSubnet
            $vmNic = New-AzureRmNetworkInterface -Name $vmNicName -ResourceGroupName $rgName -Location $rgLocation -SubnetId $vmVnet.Subnets[0].Id -PublicIpAddressId $vmPublicIP.Id

            ######################################################################################################
            # VM spacific variables
            $vmName = $rgName + 'vm01' # VM Name
            $vmHostName = 'win1709srv01' # just to distinguish between vm and host names
            $vmSize = 'Basic_A0'
            $availableVmSizes = Get-AzureRmVMSize -Location $rgLocation | Select-Object -ExpandProperty Name
            if($availableVmSizes -contains $vmSize)
            {
                "Specifized size VM is availabe @ {0} location." -f $rgLocation | Write-Host
                $vmCred = Get-Credential -Message 'Admin account for vm' -UserName 'vmAdmin' # VM admin credential

                $vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
                $vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmHostName -Credential $vmCred -ProvisionVMAgent -EnableAutoUpdate
                $vmConfig = Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName MicrosoftWindowsServer -Offer WindowsServerSemiAnnual -Skus 'Datacenter-Core-1709-smalldisk' -Version 'latest'
                $vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -id $vmNic.Id

                # Attach Storgae and disk
                $vmBlobPath = 'vhds/win1709srv01OSdisk.vhd'
                $osdiskUri = $storeACC.PrimaryEndpoints.Blob.ToString() + $vmBlobPath
                $vmDiskName = 'vm01osdisk'
                $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $vmDiskName -VhdUri $osdiskUri -CreateOption FromImage

                Write-Host '>>>>> Initialising VM creation <<<<<'
                New-AzureRmVM -ResourceGroupName $rgName -Location $rgLocation -VM $vmConfig
				# with my current subscription choice there are some limitations on the VM_Size and available locations.
            }
            else
            {
                "Specifized size VM is NOT AVAILABLE @ {0} location." -f $rgLocation | Write-Host
            }
        }
        else
        {
            'Specified storage account name is not available.`nReason: {0}' -f $storageNameCheck.Message
            break;
        }

}
else
{
    'Invalid location. Valid locations are:`n{0}' -f ($azureLocations.Location)
}