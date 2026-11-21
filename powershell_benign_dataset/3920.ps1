
$ResourceGroup = "rg-portal-staging-12"
$Location = 'uksouth'
$TemplateFile = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile = "C:\Scripts\templates\portal-staging.parameters.json"
$SubscriptionId = "ad2502d6-abba-6338-728f-b349e12657d4"
$StorageAccount = 'ststaging8261'
$VmName = "vm-portal-staging-12"
$OutputPath = 'C:\Logs\deploy-staging-2024-05-21.json'
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
