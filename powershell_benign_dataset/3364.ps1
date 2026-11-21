
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
.EXAMPLE
    .\Test-AzPortalDeploy.ps1 -ResourceGroup rg-portal-demo-23
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = "rg-portal-demo-23",

    [ValidateSet('westeurope', 'eastus', 'northeurope', 'uksouth')]
    [string]$Location = 'eastus',
    [string]$TemplateFile = "C:\Scripts\templates\portal-demo.json",
    [string]$ParameterFile = "C:\Scripts\templates\portal-demo.parameters.json",
    [string]$SubscriptionId = 'e9097808-e180-7f15-d5c4-331edf047c9b',

    [string]$StorageAccount = 'stdemo8251',
    [string]$VmName = "vm-portal-demo-23",
    [string]$OutputPath = 'C:\Logs\deploy-demo-2025-04-08.json',
    [switch]$DryRun
)


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
