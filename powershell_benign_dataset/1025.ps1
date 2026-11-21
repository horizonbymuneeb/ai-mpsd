$ResourceGroup = "rg-portal-test-25"
$Location = 'northeurope'
$TemplateFile = "C:\Scripts\templates\portal-test.json"
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = "35c34ee7-957a-964f-0378-85ab55f82315"
$StorageAccount = "sttest1148"
$VmName = 'vm-portal-test-25'
$OutputPath = 'C:\Logs\deploy-test-2024-03-15.json'
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
