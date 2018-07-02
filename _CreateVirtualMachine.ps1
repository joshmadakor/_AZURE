#See the very end for useful information for figuring out parameters for object VM provisioning
#The following code is assuming 'Import-Module AzureRM' has been run
Connect-AzureRmAccount

Function create_Resource_Group($resourceGroupName, $resourceGroupLocation) {
    Write-Host Creating Resource Group: `n $resourceGroupName `n $resourceGroupLocation -ForegroundColor Gray
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -Force
}

Function create_VM_Subnet($subnetName, $addressPrefix) {
    Write-Host Creating Virtual Subnet: `n $subnetName `n $addressPrefix -ForegroundColor Gray
    return New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $addressPrefix
}

Function create_VM_Virtual_Network($resourceGroupName, $VirtualNetworkLocation, $virtualNetworkName, $addressPrefix, $subnetName, $subnetPrefix) {
   Write-Host Creating Virtual Network: `n $virtualNetworkName `n $addressPrefix -ForegroundColor Gray
   return New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName `
                                    -AddressPrefix     $addressPrefix `
                                    -Location          $VirtualNetworkLocation `
                                    -Subnet            (create_VM_Subnet $subnetName $subnetPrefix) `
                                    -Name              $virtualNetworkName `
                                    -Force
}

Function create_VM_Public_IP_Address($resourceGroupName, $publicIPLocation) {
    Write-Host Creating Public IP Address... -ForegroundColor Gray
    return New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName `
                                      -Location $publicIPLocation `
                                      -Name "mypublicdns$(Get-Random)" `
                                      -AllocationMethod Static `
                                      -IdleTimeoutInMinutes 4
}

Function create_NetworkSecurityGroup_RDP() {
    Write-Host Creating RDP Network Security Group: `n Port 3389 -ForegroundColor Gray
    $nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  `
                                                       -Protocol Tcp `
                                                       -Direction Inbound `
                                                       -Priority 1000 `
                                                       -SourceAddressPrefix * `
                                                       -SourcePortRange * `
                                                       -DestinationAddressPrefix * `
                                                       -DestinationPortRange 3389 `
                                                       -Access Allow
    return New-AzureRmNetworkSecurityGroup             -ResourceGroupName $resourceGroup `
                                                       -Location $location `
                                                       -Name myNetworkSecurityGroup `
                                                       -SecurityRules $nsgRuleRDP `
                                                       -Force
}

Function create_VM_NIC($resourceGroupName, $nicLocation, $nicName) {
    Write-Host Creating Virtual NIC: `n $nicName -ForegroundColor Gray
    return New-AzureRmNetworkInterface -Name $nicName `
                                       -ResourceGroupName $resourceGroupName `
                                       -Location $nicLocation `
                                       -SubnetId $virtualNetwork.Subnets[0].Id `
                                       -PublicIpAddressId $privateIPAddr.Id `
                                       -NetworkSecurityGroupId $networkSecurityGroup.Id `
                                       -Force
}

Function create_VM($vmResourceGroup, $vmLocation, $vmName, $vmSize, $credentials, $publisherName, $offer, $sku, $version, $nic) {
    Write-Host Creating Virtual Machine: `n $vmName `n $vmSize `n $offer`n $sku`n $version -ForegroundColor Gray
    $vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
    $vmConfig = Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $credentials -VM $vmConfig
    $vmConfig = Set-AzureRmVMSourceImage -PublisherName $publisherName -Offer $offer -Skus $sku -Version $version -VM $vmConfig
    $vmConfig = Add-AzureRmVMNetworkInterface -Id $nic.Id -VM $vmConfig
    New-AzureRmVM -ResourceGroupName $vmResourceGroup -Location $vmLocation -VM $vmConfig
}

$vmName         = "myNewServer"
$resourceGroup  = "RG-02"
$location       = "westus"

create_Resource_Group $resourceGroup $location

$credentials    = Get-Credential -Message "Enter a username and password for the virtual machine."
$virtualNetwork = create_VM_Virtual_Network $resourceGroup $location "MyVirtualNetwork" 10.0.0.0/16 "MyVirtualSubnet" 10.0.0.0/24
$virtualNIC     = create_VM_NIC $resourceGroup $location "MyVirtualNIC"
$netSecGroup    = create_NetworkSecurityGroup_RDP
$privateIPAddr  = create_VM_Public_IP_Address $resourceGroup $location

create_VM $resourceGroup $location $vmName Standard_D1 $credentials MicrosoftWindowsServer WindowsServer 2016-DataCenter latest $virtualNIC

<#
    ------------------------------------------------------------------------------------------------------------------------------------------------

    See List of Locations:
            Get-AzureRMLocation
    Example:
        Get-AzureRMLocation | Select Location

    ------------------------------------------------------------------------------------------------------------------------------------------------

    See List of Image Publishers:
        Get-AzureRmVMImagePublisher -Location <location (see above)>
    Examples:
        get-AzureRMVMImagePublisher -Location westus | Where PublisherName -like "*MicrosoftWindows*"
        get-AzureRMVMImagePublisher -Location westus | Where PublisherName -like "*Redhat*"

    ------------------------------------------------------------------------------------------------------------------------------------------------

    See List of Image Offers:
        Get-AzureRmVMImageOffer -Location <location> -PublisherName <Publisher (see above)>
    Examples:
        Get-AzureRmVMImageOffer -Location westus -PublisherName MicrosoftWindowsDesktop
        Get-AzureRmVMImageOffer -Location westus -PublisherName Redhat

    ------------------------------------------------------------------------------------------------------------------------------------------------

    See List of SKUs
        Get-AzureRmVMImageSku -Location westus -PublisherName <Publisher)> -Offer <Offer (see above)>
    Examples:
        Get-AzureRmVMImageSku -Location westus -PublisherName MicrosoftWindowsDesktop -Offer Windows-10
        Get-AzureRmVMImageSku -Location westus -PublisherName Redhat -Offer RHEL

    ------------------------------------------------------------------------------------------------------------------------------------------------

    See List of Verions (for image)
        Get-AzureRmVMImage -Location westus -PublisherName MicrosoftWindowsDesktop -Offer Windows-10 -Skus <Sku (see above)>
    Examples:
        Get-AzureRmVMImage -Location westus -PublisherName MicrosoftWindowsDesktop -Offer Windows-10 -Skus rs4-pro | Select Version
        Get-AzureRmVMImage -Location westus -PublisherName Redhat -Offer RHEL -Skus 7.4 | Select Version
    Note:
        You can also just use "latest" when passing in a parameter for the version
    
    ------------------------------------------------------------------------------------------------------------------------------------------------
#>