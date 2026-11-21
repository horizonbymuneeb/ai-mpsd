$ResourceGroup = "rg-portal-demo-01"
$Location = 'northeurope'
$TemplateFile = 'C:\Scripts\templates\portal-demo.json'
$ParameterFile = "C:\Scripts\templates\portal-demo.parameters.json"
$SubscriptionId = "a8eb0af7-d7c9-4c82-a91a-8243b5e4ea15"
$StorageAccount = "stdemo5601"
$VmName = 'vm-portal-demo-01'
$OutputPath = 'C:\Logs\deploy-demo-2026-01-01.json'
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
