

function login_acc(){
$azureAccountName ="account"
$azurePassword = ConvertTo-SecureString "password" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
Login-AzureRmAccount -Credential $psCred
}

Try {
  Get-AzureRmContext
} Catch {
  if ($_ -like "*Login-AzureRmAccount to login*") {
    login_acc
  }
}

##variables
## Global
##resource group $RG = "VNET-RG
$ResourceGroupName = "VNET-RG2"
$location = "westeurope"

## Storage
$StorageName = "bucostorage"
$StorageType = "Standard_GRS"

## Network
$VNetName = "vNet_LAN"
$LAN_Interface = "LAN"
$LAN_Subnet = "LAN"
$VNetLANAddressPrefix = "10.0.0.0/16"
$VNetLANSubnetAddressPrefix = "10.0.10.0/24"
##HB for cluster 
$HB_Interface = "HB"
$HB_Subnet = "HB"
$VNetHBAddressPrefix = "192.168.0.0/16"
$VNetHBSubnetAddressPrefix = "192.168.100.0/24"
$static_ip = "10.0.10.100"

#####
## Compute
$VMName = "LYNX1"
$ComputerName = "LYNX1"
$VMSize = "Standard_D1"
$OSDiskName = $VMName + "OSDisk"

Write-Host -ForegroundColor Yellow "Deploying vm........."

Write-Host -ForegroundColor Yellow "VM name:  " $VMName

Write-Host -ForegroundColor Yellow "in subnet " $VNetLANSubnetAddressPrefix
 
Write-Host -ForegroundColor Yellow "Ip address" $static_ip



New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
# Storage
#$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location
# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name NSG_SSH  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 22 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $location `
  -Name myNetworkSecurityGroup -SecurityRules $nsgRuleSSH
# Resource Group

##########create vnet and subnets
# Network
$PIp = New-AzureRmPublicIpAddress -Name $LAN_Interface -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $LAN_Subnet -AddressPrefix $VNetLANSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetLANAddressPrefix -Subnet $SubnetConfig
$Interface = New-AzureRmNetworkInterface -Name $LAN_Interface -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id -NetworkSecurityGroupId $nsg.Id

## set static IP
$nic=Get-AzureRmNetworkInterface -Name LAN -ResourceGroupName $ResourceGroupName
$nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$nic.IpConfigurations[0].PrivateIpAddress = "$static_ip"
Set-AzureRmNetworkInterface -NetworkInterface $nic


# Compute



## Setup local VM object
  $securePassword = Read-Host "Enter password :  ... " 
 $securePassword = ConvertTo-SecureString $securePassword -AsPlainText -Force
 $cred = New-Object System.Management.Automation.PSCredential ("sysadmin", $securePassword)

$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize   | `
 Set-AzureRmVMOperatingSystem  -Linux  -ComputerName $ComputerName  -Credential $cred -DisablePasswordAuthentication  | `
 Set-AzureRmVMSourceImage  -PublisherName "Oracle" -Offer "Oracle-Linux" -Skus "7.3" -Version "latest" | `
 Add-AzureRmVMNetworkInterface  -Id $Interface.Id
 #$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
 #$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
$sshPublicKey = Get-Content "C:\temp\id_rsa.pub"
Add-AzureRmVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/sysadmin/.ssh/authorized_keys"


## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine

