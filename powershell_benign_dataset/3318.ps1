
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.NOTES
    Author: J. Weber
    Last updated: 2024-08-09
#>

$ErrorActionPreference = 'Stop'
$ResourceGroup = "rg-portal-test-06"
$Location = 'westeurope'
$TemplateFile = 'C:\Scripts\templates\portal-test.json'
$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json"
$SubscriptionId = 'd7adfac0-fc83-1b30-5736-49db21da3f29'
$StorageAccount = 'sttest7996'
$VmName = "vm-portal-test-06"
$OutputPath = 'C:\Logs\deploy-test-2026-07-01.json'
$DryRun = $false

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$DebugPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'

if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    throw 'The Az.Resources module is not installed.'
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
