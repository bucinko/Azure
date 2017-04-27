
########################
#variables
$VNetName  = "vNet_LAN"
$LAN = "LAN"
$GWSubName = "GatewaySubnet"
$adressspace = "192.168.0.0/16"
$LANSubPrefix = "192.168.1.0/24"
$GWSubPrefix = "192.168.200.0/26"
$VPNClientAddressPool = "172.16.201.0/24"
$RG = "VNET-RG2"
$Location = "westeurope"
$DNS = "8.8.8.8"
$GWName =  "GW1"
$GWIPName = "GWPIP"
$GWIPconfName = "gwipconf"
$yesno = $true



function  yesnoprompt  {
Write-host "Would you like generate new root cert and clinet cert ? (Default is YES)" -ForegroundColor Yellow 
    $Readhost = Read-Host " ( y / n ) " 
    Switch ($ReadHost) 
     { 
       Y {Write-host "Yes, generate certs "; $yesno=$true} 
       N {Write-Host "No, do not generate cert "; $yesno=$false} 
       Default {Write-Host "YES "; $yesno=$true} 
     } 

     }
function login_acc(){
$azureAccountName ="<your account name>"
$azurePassword = ConvertTo-SecureString "<your password" -AsPlainText -Force
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


########network config
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RG -Name $VNetName
$vnet.AddressSpace.AddressPrefixes.Add($adressspace)
Add-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet -AddressPrefix $GWSubPrefix
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

#$gwsub = New-AzureRmVirtualNetworkSubnetConfig -Name $GWSubName -AddressPrefix $GWSubPrefix
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet
$pip = New-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic
$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName -Subnet $subnet -PublicIpAddress $pip


### 
#generate root cert and then client cert

yesnoprompt
if ($yesno){
       
$doesExists = Get-ChildItem  Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*P2Sroot*" } 

 
if(!$doesExists) {
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SChildCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
       
 
 }

 Get-ChildItem  Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*P2Sroot*" } | Export-Certificate -FilePath C:\temp\S2Pcert.cer -Type CERT
       }

$P2SRootCertName = "S2ProotCert.cer"
$filePathForCert = "C:\temp\S2Pcert.cer"
$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($filePathForCert)
$CertBase64 = [system.convert]::ToBase64String($cert.RawData)
$p2srootcert = New-AzureRmVpnClientRootCertificate -Name $P2SRootCertName -PublicCertData $CertBase64

New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $RG `
-Location $Location -IpConfigurations $ipconf -GatewayType Vpn `
-VpnType RouteBased -EnableBgp $false -GatewaySku Standard `
-VpnClientAddressPool $VPNClientAddressPool -VpnClientRootCertificates $p2srootcert







