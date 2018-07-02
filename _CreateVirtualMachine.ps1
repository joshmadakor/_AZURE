## VM Account
# Credentials for Local Admin account you created in the sysprepped (generalized) vhd image
$VMLocalAdminUser = "LocalAdminUser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Password" -AsPlainText -Force

## Azure Account
$LocationName      = "westus"
$ResourceGroupName = "RG-01"

# This a Premium_LRS storage account. 
# It is required in order to run a client VM with efficiency and high performance.
$StorageAccount    = "wowhijoshdisklol"
    
## VM
$OSDiskName     = "MyClient"
$ComputerName   = "MyClientVM"
$OSDiskUri      = "https://wowhijoshdisklol.blob.core.windows.net/disks/MyOSDisk.vhd"
$SourceImageUri = "https://wowhijoshdisklol.blob.core.windows.net/vhds/MyOSImage.vhd"
$VMName         = "MyVM"

# Modern hardware environment with fast disk, high IOPs performance. 
# Required to run a client VM with efficiency and performance
$VMSize         = "Standard_DS3" 
$OSDiskCaching  = "ReadWrite"
$OSCreateOption = "FromImage"
    
## Networking
$DNSNameLabel        = "mydnsname" # mydnsname.westus.cloudapp.azure.com
$NetworkName         = "MyNet"
$NICName             = "MyNIC"
$PublicIPAddressName = "MyPIP" 
$SubnetName          = "MySubnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix   = "10.0.0.0/16"

<#
1. Create Subnet
2. Create Virtual Network
3. Create Private IP address
4. Create NIC

#>

New-AzureRmResourceGroup  -Name $ResourceGroupName -Location $LocationName
New-AzureRmStorageAccount -ResourceGroupName RG-01 -Name $StorageAccount -Location westus


$SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name              $SubnetName `
                                                      -AddressPrefix     $SubnetAddressPrefix   # "MySubnet"# "10.0.0.0/24"

$Vnet         = New-AzureRmVirtualNetwork             -Name              $NetworkName `
                                                      -ResourceGroupName $ResourceGroupName `
                                                      -Location          $LocationName `
                                                      -AddressPrefix     $VnetAddressPrefix `
                                                      -Subnet            $SingleSubnet          # "MyNet" # "RG-01" # "westus" # "10.0.0.0/16" # <Subnet Object>

$PIP          = New-AzureRmPublicIpAddress            -Name              $PublicIPAddressName `
                                                      -DomainNameLabel   $DNSNameLabel `
                                                      -ResourceGroupName $ResourceGroupName `
                                                      -Location          $LocationName `
                                                      -AllocationMethod  Dynamic                # "MyPIP" # "mydnsname" # "RG-01" # "westus"

$NIC          = New-AzureRmNetworkInterface           -Name              $NICName `
                                                      -ResourceGroupName $ResourceGroupName `
                                                      -Location          $LocationName `
                                                      -SubnetId          $Vnet.Subnets[0].Id `
                                                      -PublicIpAddressId $PIP.Id                # "MyNIC" # "RG-01" # "westus" # 10.0.0.0/24 (?) # <ip address>
<#
$Credential  = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword) #>
$Credential  = Get-Credential

$VirtualMachine = New-AzureRmVMConfig -VMName $VMName `
                                      -VMSize $VMSize 

$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine `
                  -ComputerName                    $ComputerName `
                  -Credential                      $Credential `
                  -Windows `
                  -ProvisionVMAgent `
                  -EnableAutoUpdate                                  # <Object> # "MyClientVM" # <manually typed or specified>

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine `
                                                -Id $NIC.Id

$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine `
                                      -Name $OSDiskName `
                                      -VhdUri $OSDiskUri `
                                      -SourceImageUri $SourceImageUri `
                                      -Caching $OSDiskCaching `
                                      -CreateOption $OSCreateOption `
                                      -Windows # <Object> # "MyClient" # "https://Mydisk.blob.core.windows.net/disks/MyOSDisk.vhd" # "https://Mydisk.blob.core.windows.net/vhds/MyOSImage.vhd" # "ReadWrite" # "FromImage"

New-AzureRmVM -ResourceGroupName $ResourceGroupName `
              -Location $LocationName `
              -VM $VirtualMachine `
              -Verbose # "RG-01" # "westus" # <object>

<#   
This example takes an existing sys-prepped, generalized custom operating system image and attaches a data disk to it, provisions a new network, deploys the VHD, and runs it.
This script can be used for automatic provisioning because it uses the local virtual machine admin credentials inline instead of calling Get-Credential which requires user interaction.
This script assumes that you are already logged into your Azure account. You can confirm your login status by using the Get-AzureSubscription cmdlet.
#>
