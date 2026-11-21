$ResourceGroup = "rg-portal-test-12"
$Location = 'northeurope'
$TemplateFile = 'C:\Scripts\templates\portal-test.json'
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = 'a384bbd3-8d90-1d89-1589-a88e74cb5698'
$StorageAccount = 'sttest5790'
$VmName = "vm-portal-test-12"
$OutputPath = 'C:\Logs\deploy-test-2025-02-17.json'
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
