
$ResourceGroup = 'rg-portal-staging-03'
$Location = 'northeurope'
$TemplateFile = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = "d8798430-079d-db9b-8911-049e1675540d"
$StorageAccount = "ststaging0085"
$VmName = 'vm-portal-staging-03'
$OutputPath = "C:\Logs\deploy-staging-2025-07-20.json"
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
