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
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Test-AzPortalDeploy.ps1 -ResourceGroup rg-portal-demo-21
.EXAMPLE
    .\Test-AzPortalDeploy.ps1 -Location uksouth -DryRun
#>

$ResourceGroup = 'rg-portal-demo-21'
$Location = 'uksouth'
$TemplateFile = "C:\Scripts\templates\portal-demo.json"
$ParameterFile = 'C:\Scripts\templates\portal-demo.parameters.json'
$SubscriptionId = "84b5c6e3-6f91-421f-c4ed-788e7d10c49d"
$StorageAccount = "stdemo2306"
$VmName = "vm-portal-demo-21"
$OutputPath = 'C:\Logs\deploy-demo-2025-11-01.json'
$DryRun = $false

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

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
