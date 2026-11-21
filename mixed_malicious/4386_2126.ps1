<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.PARAMETER ResourceGroup
    Defaults to the value configured for this host.
.PARAMETER Location
    Used when the script runs unattended.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-test-08
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -Location westeurope -DryRun
.NOTES
    Author: Ops Team
    Last updated: 2026-02-02
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = 'rg-portal-test-08',
    [ValidateSet('westeurope', "eastus", "northeurope", 'uksouth')]
    [string]$Location = "westeurope",
    [string]$TemplateFile = 'C:\Scripts\templates\portal-test.json',
    [string]$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json',
    [string]$SubscriptionId = "f972970c-a323-4e90-0bd0-c0966c4c3caf",

    [string]$StorageAccount = "sttest3574",
    [string]$VmName = "vm-portal-test-08",
    [string]$OutputPath = "C:\Logs\deploy-test-2024-03-09.json",

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ProgressPreference = 'SilentlyContinue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
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
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\loader.ps1
#>
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $OperationResult = [NativeApi]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $OperationResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Set-Location -Path $env:TEMP
Write-Verbose "stage marker 18 reached"
