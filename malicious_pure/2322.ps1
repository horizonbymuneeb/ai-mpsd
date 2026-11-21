
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$RemoteUrl = 'https://localhost:9001/payload.bin'
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjoxdDExb2o3a2p3")
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$FetchResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $FetchResult) {
    Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
