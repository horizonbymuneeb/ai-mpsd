$ResourceGroup  = 'rg-portal-demo-02'
$Location       = "westeurope"
$TemplateFile   = "C:\Scripts\templates\portal-demo.json"
$ParameterFile  = "C:\Scripts\templates\portal-demo.parameters.json"
$SubscriptionId = "137786eb-5ccd-79e2-4d97-bdcd411cd1cc"
$StorageAccount = "stdemo7860"
$VmName         = "vm-portal-demo-02"
$OutputPath     = 'C:\Logs\deploy-demo-2024-02-12.json'
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
