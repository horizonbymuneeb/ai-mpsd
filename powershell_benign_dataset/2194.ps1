
$ResourceGroup  = "rg-portal-staging-16"
$Location       = "westeurope"
$TemplateFile   = "C:\Scripts\templates\portal-staging.json"
$ParameterFile  = "C:\Scripts\templates\portal-staging.parameters.json"
$SubscriptionId = "ddc469c3-6c96-9332-11bd-301fa2e9ae93"
$StorageAccount = "ststaging4427"
$VmName         = 'vm-portal-staging-16'
$OutputPath     = "C:\Logs\deploy-staging-2026-01-27.json"
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
