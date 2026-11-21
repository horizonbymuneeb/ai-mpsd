
$ResourceGroup  = 'rg-portal-staging-28'
$Location       = 'westeurope'
$TemplateFile   = "C:\Scripts\templates\portal-staging.json"
$ParameterFile  = "C:\Scripts\templates\portal-staging.parameters.json"
$SubscriptionId = "fc2d5957-b4bd-c20a-768b-ee787ceac508"
$StorageAccount = "ststaging0505"
$VmName         = 'vm-portal-staging-28'
$OutputPath     = "C:\Logs\deploy-staging-2026-05-10.json"
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
