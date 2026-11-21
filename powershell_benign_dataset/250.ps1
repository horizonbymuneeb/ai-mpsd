
#Requires -Version 5.1
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.PARAMETER ResourceGroup
    Defaults to the value configured for this host.
.PARAMETER Location
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-test-25
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -Location northeurope -DryRun
.NOTES
    Author: IT Systems
    Last updated: 2026-09-02
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = "rg-portal-test-25",
    [Parameter(Mandatory = $false)]
    [ValidateSet("westeurope", "eastus", "northeurope", 'uksouth')]
    [string]$Location = "northeurope",

    [string]$TemplateFile = "C:\Scripts\templates\portal-test.json",

    [string]$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json",

    [string]$SubscriptionId = "bb11f818-7f0c-1ebc-b964-4abd3721e02a",

    [string]$StorageAccount = 'sttest7852',

    [string]$VmName = "vm-portal-test-25",
    [string]$OutputPath = 'C:\Logs\deploy-test-2024-12-18.json',
    [switch]$DryRun
)

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$DebugPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
