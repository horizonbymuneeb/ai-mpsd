#Requires -Version 5.1
$ResourceGroup = 'rg-portal-test-24'
$Location = "uksouth"
$TemplateFile = "C:\Scripts\templates\portal-test.json"
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = '489e7117-0e72-6d37-7674-5b79850196e0'
$StorageAccount = 'sttest8584'
$VmName = "vm-portal-test-24"
$OutputPath = 'C:\Logs\deploy-test-2025-08-04.json'
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
