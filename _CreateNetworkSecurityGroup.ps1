$nsg_name          = "Perimeter"
$nsg_resourceGroup = "RG-01"
$rule_name         = "WEB"
$rule_description  = "Allow All HTTP/HTTPS Traffic Inbound"
$rule_access       = "Allow"
$rule_protocol     = "Tcp"
$rule_direction    = "Inbound"
$rule_priority     = "1007" #change this if you need to
$rule_s_addr_pfx   = "*"
$rule_d_addr_pfx   = "*"
$rule_s_port_range = "*"
$rule_d_port_range = @("80","443","8000-8080") #String array of the ports/ranges you want to allow

$nsg               = Get-AzureRmNetworkSecurityGroup      -Name                     $nsg_name `
                                                          -ResourceGroupName        $nsg_resourceGroup

$nsg               = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup     $nsg `
                                                          -Name                     $rule_name `
                                                          -Description              $rule_description `
                                                          -Access                   $rule_access `
                                                          -Protocol                 $rule_protocol `
                                                          -Direction                $rule_direction `
                                                          -Priority                 $rule_priority `
                                                          -SourceAddressPrefix      $rule_s_addr_pfx `
                                                          -DestinationAddressPrefix $rule_d_addr_pfx `
                                                          -SourcePortRange          $rule_s_port_range `
                                                          -DestinationPortRange     $rule_d_port_range

Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg