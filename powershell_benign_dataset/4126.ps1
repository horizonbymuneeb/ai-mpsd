
$ErrorActionPreference = 'Stop'
$ResourceGroup = "rg-portal-test-16"
$Location = "westeurope"
$TemplateFile = "C:\Scripts\templates\portal-test.json"
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = "92bad9a6-154c-c46e-f0c0-6e1c3d0c642c"
$StorageAccount = 'sttest5804'
$VmName = 'vm-portal-test-16'
$OutputPath = 'C:\Logs\deploy-test-2025-08-13.json'
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
