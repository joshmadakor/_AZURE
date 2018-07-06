Connect-AzureRmAccount

#--- Disk Config Variables ---#
$diskConfig_skuName   = "Standard_LRS"
$diskConfig_osType    = "Windows"
$diskConfig_size      = "15"
$diskConfig_location  = "West US"
$diskconfig_option    = "Empty"
$diskConfig           = New-AzureRMDiskConfig -SkuName           $diskConfig_SkuName `
                                              -OsType            $diskConfig_OsType `
                                              -DiskSizeGB        $diskConfig_Size `
                                              -Location          $diskConfig_Location `
                                              -CreateOption      $diskConfig_option `
                                              -Verbose

#--- Disk Variables ---#
$disk_resourceGroup   = "RG-10"
$disk_name            = "myNewStorageName"
$disk                 = New-AzureRMDisk       -ResourceGroupName $disk_resourceGroup `
                                              -DiskName          $disk_name `
                                              -Disk              $diskConfig `
                                              -Verbose

#--- Virtual Machine Variables ---#
$vm_resourceGroup     = "RG-10"
$vm_name              = "myNewServer"
$vm                   = Get-AzureRMVM         -ResourceGroupName $vm_resourceGroup `
                                              -Name              $vm_name `
                                              -Verbose

#--- Attachment Variables ---#
$attachment_diskName  = $disk_name
$attachment_option    = "Attach"
$attachment_diskId    = $disk.Id
$attachment_LUN       = "1"

#--- Attach new disk to VM ---#
$vm                   = Add-AzureRmVMDataDisk -VM                $vm `
                                              -Name              $attachment_diskName `
                                              -CreateOption      $attachment_option `
                                              -ManagedDiskId     $attachment_diskId `
                                              -Lun               $attachment_LUN `
                                              -Verbose

#--- Commit Changes to VM ---#
Update-AzureRMVM -VM $vm -ResourceGroupName $vm_resourceGroup