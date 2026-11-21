$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-portal-staging-08"
$Location = "uksouth"
$TemplateFile = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile = "C:\Scripts\templates\portal-staging.parameters.json"
$SubscriptionId = '731eb414-1220-3c9c-1ab2-a0ffbdd9e830'
$StorageAccount = 'ststaging6899'
$VmName = 'vm-portal-staging-08'
$OutputPath = "C:\Logs\deploy-staging-2024-09-28.json"
$DryRun = $false

$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant "contoso.com" -Subscription $SubscriptionId
}

if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
}
$DeploymentName = "portal-" + (Get-Date -Format 'yyyyMMdd-HHmm')
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -Name $DeploymentName
Write-Host ("Deployment {0}: {1}" -f $deployment.DeploymentName, $deployment.ProvisioningState) -ForegroundColor Green
