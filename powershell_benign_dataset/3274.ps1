$ErrorActionPreference = 'Stop'
$ResourceGroup  = 'rg-portal-staging-31'
$Location       = "northeurope"
$TemplateFile   = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile  = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = "51036a05-4264-77a0-2756-ba5de44f8cbb"
$StorageAccount = 'ststaging4289'
$VmName         = "vm-portal-staging-31"
$OutputPath     = 'C:\Logs\deploy-staging-2024-12-02.json'
$DryRun         = $false


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
