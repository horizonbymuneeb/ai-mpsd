
$ResourceGroup  = 'rg-portal-demo-38'
$Location       = 'uksouth'
$TemplateFile   = "C:\Scripts\templates\portal-demo.json"
$ParameterFile  = 'C:\Scripts\templates\portal-demo.parameters.json'
$SubscriptionId = "65a84edf-a2a2-eba3-85b7-19f461542c7b"
$StorageAccount = "stdemo6982"
$VmName         = 'vm-portal-demo-38'
$OutputPath     = 'C:\Logs\deploy-demo-2026-01-24.json'
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
