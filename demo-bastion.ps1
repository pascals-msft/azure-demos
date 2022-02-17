# Interactive demo:
# Azure Bastion native client connections
# Prerequisites:
#   PowerShell - https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows
#   Azure PowerShell for Windows - https://docs.microsoft.com/en-us/powershell/azure/install-az-ps
#   Azure CLI for Windows - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows
#   An SSH key must be present at "${env:USERPROFILE}\.ssh\id_rsa"
# References:
#   https://docs.microsoft.com/en-us/azure/bastion/connect-native-client-windows

Write-Output "Don't run this as a script!"; Return

# *** begin here ***

# *** Connect to managing tenant ***
Disconnect-AzAccount
Connect-AzAccount
Get-AzContext | Format-List

$demo = "demo" + (Get-Random -Minimum 1000 -Maximum 10000); $demo
$rgname = $demo + "rg"
$vnetname = $demo + "vnet"
$bastionname = $demo + "bastion"
$vmname_win = $demo + "win"
$vmname_linux = $demo + "linux"
$location = "northeurope"

# VM admin's username
$vmadminname = "vmadmin"
# Windows VM admin's password
$vmadminpwd = Read-Host "Windows VM local admin's ($vmadminname) password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vmadminpwd)
$vmadminpwd_clear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

# Resource group
New-AzResourceGroup -Name $rgname -Location $location

# VNet
$subnet1 = New-AzVirtualNetworkSubnetConfig -Name 'default' -AddressPrefix 10.10.0.0/24
$subnet2 = New-AzVirtualNetworkSubnetConfig -Name 'AzureBastionSubnet' -AddressPrefix 10.10.1.0/24
$vnet = New-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rgname -Location $location -AddressPrefix 10.10.0.0/16 -Subnet $subnet1,$subnet2

# Windows VM, no public IP - use 'az vm image list -o table' to find the image
az vm create --image Win2019Datacenter -g $rgname -n $vmname_win --admin-username $vmadminname --admin-password "$vmadminpwd_clear" --public-ip-address '""' -o yamlc
$vm_win = Get-AzVM -ResourceGroupName $rgname -Name $vmname_win

# Linux VM, no public IP
az vm create --image UbuntuLTS -g $rgname -n $vmname_linux --admin-username "$vmadminname" --public-ip-address '""' -o yamlc
$vm_linux = Get-AzVM -ResourceGroupName $rgname -Name $vmname_linux

# Azure Bastion
$bastionpip = New-AzPublicIpAddress -ResourceGroupName $rgname -Name "${bastionname}_pip" -Location $location -AllocationMethod Static -Sku Standard
$bastion = New-AzBastion -Name $bastionname -ResourceGroupName $rgname -Sku "Standard" -VirtualNetwork $vnet -PublicIpAddress $bastionpip -Verbose

# set the Bastion "Native client support" option
az resource update --set properties.enableTunneling=true --ids $bastion.Id -o yamlc --verbose

# Connect to Windows VM
az network bastion rdp --name $bastionname --resource-group $rgname --target-resource-id $vm_win.Id

# Connect to Linux VM
$sshkey = "${env:USERPROFILE}\.ssh\id_rsa"
az network bastion ssh --name $bastionname --resource-group $rgname --target-resource-id $vm_linux.Id --auth-type "ssh-key" --username "$vmadminname" --ssh-key "$sshkey"

# delete everything
az group delete -g $rgname -y --no-wait
