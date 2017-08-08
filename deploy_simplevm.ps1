#Login-AzureRmAccount

$URI       = 'https://raw.githubusercontent.com/bucinko/azure-quickstart-templates/master/101-vm-simple-windows/azuredeploy.json'
$paramURI  = 'https://raw.githubusercontent.com/bucinko/azure-quickstart-templates/master/101-vm-simple-windows/azuredeploy.parameters.json'

$Location  = 'West Europe'
$rgname    = 'bucinorg'
$saname    = 'bucinosa'     # Lowercase required
#$addnsName = 'bucinoad'     # Lowercase required

$parameters = @{}

if (Test-AzureRmDnsAvailability -DomainNameLabel "bucinkocloud" -Location $Location)
{ 'Available' } else { 'Taken. addnsName must be globally unique.' }
New-AzureRmResourceGroup -Name $rgname -Location $Location

$password = "jUcR=G=!-8um)z+L"
$SecurePassword = $password | ConvertTo-SecureString -AsPlainText -Force

  
New-AzureRmResourceGroupDeployment -ResourceGroupName $rgname -TemplateFile $URI -TemplateParameterFile $paramURI -adminUsername "sysadmin" -adminPassword $SecurePassword -dnsLabelPrefix "bucinkocloud"

#Write-Host -ForegroundColor Yellow "Do you want to delete RG :  +$rgname  Y/N"
#$answear = Read-Host

#Switch ($answear){ 

#Y  {Remove-AzureRmResourceGroup -Name $rgname -Force -Verbose}
#N { break }
 
#}