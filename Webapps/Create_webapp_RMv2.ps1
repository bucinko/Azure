
$default_RG ="webapps-RG"
$ServicePlanName = "webapp_servicePlan"
$WebAppName = Read-Host " write website desired name"
$ErrorActionPreference = "Stop"
$default_location ="westeurope"

 

# Remove-AzureRmResourceGroup -Name $default_RG -Force


Write-Host -ForegroundColor Green "Creating folowing values "
Write-Host -ForegroundColor Green "Resource Group: " $default_RG
Write-Host -ForegroundColor Green "Service Plan: "   $ServicePlanName
Write-Host -ForegroundColor Green "web app name: "   $WebAppName
Write-Host -ForegroundColor Green "Location:   "     $default_location





##check if rg exists if not create

 Get-AzureRmResourceGroup -Name $default_RG -ev notPresent -ea 0
if ($notPresent) {
Write-Host -ForegroundColor Yellow " Resource group does not exist creating .." $default_RG 
  New-AzureRmResourceGroup -Name $default_RG -Location $default_location
}

#Create an App Service plan if not exists


New-AzureRmAppServicePlan -Name $ServicePlanName -Location $default_location `
-ResourceGroupName $default_RG -Tier Free 

New-AzureRmWebApp -Name $WebAppName -Location $default_location -AppServicePlan $ServicePlanName `
-ResourceGroupName $default_RG



Write-Host -ForegroundColor Green "Upgrading service plan and creating deployments slots... "

#upgrade service plan to allow Deployment slots  FIX and PROD
Set-AzureRmAppServicePlan -Name $ServicePlanName -ResourceGroupName $default_RG `
-Tier Standard

New-AzureRmWebAppSlot -Name $webappname -ResourceGroupName $default_RG `
-Slot FIX

New-AzureRmWebAppSlot -Name $webappname -ResourceGroupName $default_RG `
-Slot PROD

#deploy sample app from git hub to FIX slot

$gitrepo="https://github.com/bucinko/https-github.com-Azure-Samples-app-service-web-html-get-started.git"
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}


Set-AzureRmResource -PropertyObject $PropertiesObject -ResourceGroupName $default_RG `
-ResourceType Microsoft.Web/sites/slots/sourcecontrols -ResourceName "$WebAppName/FIX/web" `
-ApiVersion 2015-08-01 -Force

 




#assigning custom domains precreated in dns
# Before continuing, go to your DNS configuration UI for your custom domain and follow the 
# instructions at https://aka.ms/appservicecustomdns to configure a CNAME record for the 
# hostname "www" and point it your web app's default domain name.
$fqdn_prod = "www.bucinko.cloud"
 $fqdn_fix = "fix.bucinko.cloud"


Write-Host  -ForegroundColor Green "Configure a CNAME record that maps $fqdn_prod to $webappname-prod.azurewebsites.net and $fqdn_fix to $webappname-fix.azurewebsites.net"
Read-Host "Press [Enter] key when ready ..."

 
Get-AzureWebsite -Name "$webappname(PROD)" | Set-AzureWebsite -HostNames @("$fqdn_prod")
 
Get-AzureWebsite -Name "$webappname(FIX)" | Set-AzureWebsite -HostNames @("$fqdn_fix")



#bind custom certificate

#New-AzureRmWebAppSSLBinding -WebAppName $webappname -ResourceGroupName $default_RG -Name $fqdn `
#-CertificateFilePath $pfxPath -CertificatePassword $pfxPassword -SslState SniEnabled


