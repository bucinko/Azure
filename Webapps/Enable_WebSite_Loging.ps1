#we will continue with formerly set up variables
# https://docs.microsoft.com/en-us/azure/app-service-web/scripts/app-service-powershell-monitor?toc=%2fpowershell%2fmodule%2ftoc.json

$default_RG ="webapps-RG"
$ServicePlanName = "webapp_servicePlan"
$WebAppName = Read-Host " write website desired name"
$ErrorActionPreference = "Stop"
$default_location ="westeurope"

#enable web site logging

Set-AzureRMWebApp -RequestTracingEnabled $True -HttpLoggingEnabled $True -DetailedErrorLoggingEnabled $True -ResourceGroupName $default_RG -Name $WebAppName


# Make a Request
Invoke-WebRequest -Method "Get" -Uri https://bucoweb.azurewebsites.net/404 -ErrorAction SilentlyContinue

Get-AzureRMWebAppMetrics -ResourceGroupName $ResourceGroupName -Name $WebAppName -Metrics
# Download the Web App Logs
 #Get-AzureWebsiteLog -Name "bucoweb(PROD)"