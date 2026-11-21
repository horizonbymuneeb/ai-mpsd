
$ResourceGroup = 'rg-portal-demo-18'
$Location = "northeurope"
$TemplateFile = 'C:\Scripts\templates\portal-demo.json'
$ParameterFile = "C:\Scripts\templates\portal-demo.parameters.json"
$SubscriptionId = '5495afb6-0c65-b889-797d-85f3c8d1a434'
$StorageAccount = 'stdemo3610'
$VmName = 'vm-portal-demo-18'
$OutputPath = 'C:\Logs\deploy-demo-2024-07-11.json'
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
