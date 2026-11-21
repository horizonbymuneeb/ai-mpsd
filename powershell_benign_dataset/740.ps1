$ResourceGroup  = 'rg-portal-test-15'
$Location       = "northeurope"
$TemplateFile   = 'C:\Scripts\templates\portal-test.json'
$ParameterFile  = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = '8732661c-f426-eea1-154d-81896dad777e'
$StorageAccount = 'sttest7702'
$VmName         = 'vm-portal-test-15'
$OutputPath     = "C:\Logs\deploy-test-2024-02-28.json"
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
