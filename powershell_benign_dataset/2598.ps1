
$ResourceGroup = "rg-portal-test-27"
$Location = 'eastus'
$TemplateFile = 'C:\Scripts\templates\portal-test.json'
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = "552c5ca0-01c8-f51d-c849-5a947df0c0a9"
$StorageAccount = "sttest1775"
$VmName = 'vm-portal-test-27'
$OutputPath = 'C:\Logs\deploy-test-2025-05-16.json'
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
