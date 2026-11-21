$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-portal-staging-15"
$Location = 'westeurope'
$TemplateFile = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = '238a7a28-fc4d-7cf5-814a-3959200d6b73'
$StorageAccount = 'ststaging5489'
$VmName = "vm-portal-staging-15"
$OutputPath = "C:\Logs\deploy-staging-2024-03-23.json"
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
