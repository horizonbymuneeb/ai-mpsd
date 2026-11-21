#Requires -Version 5.1
$ResourceGroup  = 'rg-portal-staging-29'
$Location       = 'northeurope'
$TemplateFile   = "C:\Scripts\templates\portal-staging.json"
$ParameterFile  = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = "70a805e9-7505-f513-eb95-8661654878dd"
$StorageAccount = "ststaging7973"
$VmName         = "vm-portal-staging-29"
$OutputPath     = "C:\Logs\deploy-staging-2026-11-14.json"
$DryRun         = $false


$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant 'contoso.com' -Subscription $SubscriptionId
}

if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
}
$DeploymentName = "portal-" + (Get-Date -Format 'yyyyMMdd-HHmm')
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -Name $DeploymentName
Write-Host ("Deployment {0}: {1}" -f $deployment.DeploymentName, $deployment.ProvisioningState) -ForegroundColor Green
