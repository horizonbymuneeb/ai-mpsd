$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-portal-staging-24"
$Location = "eastus"
$TemplateFile = "C:\Scripts\templates\portal-staging.json"
$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = '98fa927c-9a2d-2d9c-bb0e-17620699c51a'
$StorageAccount = 'ststaging0928'
$VmName = "vm-portal-staging-24"
$OutputPath = "C:\Logs\deploy-staging-2024-11-28.json"
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
