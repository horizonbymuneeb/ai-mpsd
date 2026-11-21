
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
.PARAMETER Location
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-staging-08
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -Location northeurope -DryRun
.NOTES
    Author: J. Weber
    Last updated: 2024-03-22
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = "rg-portal-staging-08",

    [ValidateSet("westeurope", 'eastus', 'northeurope', 'uksouth')]
    [string]$Location = 'northeurope',
    [string]$TemplateFile = "C:\Scripts\templates\portal-staging.json",
    [string]$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json',
    [string]$SubscriptionId = '5bfab711-4968-150c-99c6-1190b246e847',
    [string]$StorageAccount = 'ststaging7333',
    [string]$VmName = "vm-portal-staging-08",

    [string]$OutputPath = 'C:\Logs\deploy-staging-2024-09-01.json',
    [switch]$DryRun
)
$ErrorActionPreference = "Stop"
$InformationPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'

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
