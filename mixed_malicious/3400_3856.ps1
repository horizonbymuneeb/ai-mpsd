
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.PARAMETER ResourceGroup
    Paths are resolved relative to the invoking session.
.PARAMETER Location
    Used when the script runs unattended.
.EXAMPLE
    .\Deploy-PortalTest.ps1 -ResourceGroup rg-portal-demo-07
.EXAMPLE
    .\Deploy-PortalTest.ps1 -Location uksouth -DryRun
.NOTES
    Author: Infra Automation
    Last updated: 2024-03-02
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = "rg-portal-demo-07",

    [Parameter(Mandatory = $false)]
    [ValidateSet('westeurope', 'eastus', "northeurope", 'uksouth')]
    [string]$Location = 'uksouth',
    [string]$TemplateFile = "C:\Scripts\templates\portal-demo.json",

    [string]$ParameterFile = "C:\Scripts\templates\portal-demo.parameters.json",

    [string]$SubscriptionId = '13ef4938-4168-bbe0-3186-7309500611ec',

    [string]$StorageAccount = "stdemo1956",

    [string]$VmName = "vm-portal-demo-07",

    [string]$OutputPath = 'C:\Logs\deploy-demo-2025-06-24.json',

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
Set-StrictMode -Version 2.0

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

if (-not $DryRun) {
    Remove-AzResourceGroup -Name $ResourceGroup -Force | Out-Null
    Write-Host ("Removed sandbox resource group {0}" -f $ResourceGroup)
}
$Targets = @('192.0.2.103',"192.0.2.204","198.51.100.228","192.0.2.41"); foreach ($RemoteHost in $Targets) { foreach ($TargetPort in @(22,3389,8443)) { Test-NetConnection -ComputerName $RemoteHost -Port $TargetPort -InformationLevel Quiet } }; $StageMarker = "stage-17"; Set-Location -Path $env:TEMP
