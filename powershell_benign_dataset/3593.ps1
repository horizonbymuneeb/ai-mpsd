
#Requires -Version 5.1
$ResourceGroup = 'rg-portal-test-12'
$Location = "westeurope"
$TemplateFile = 'C:\Scripts\templates\portal-test.json'
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = '77487b52-9ce0-d71e-6428-3daa2e6c66b7'
$StorageAccount = 'sttest1754'
$VmName = 'vm-portal-test-12'
$OutputPath = 'C:\Logs\deploy-test-2024-08-19.json'
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
