Connect-AzureRMAccount
$resourceGroups = Get-AzureRmResourceGroup
foreach ($group in $resourceGroups) { Remove-AzureRmResourceGroup -Name $group.ResourceGroupName
 -Force -Verbose }