[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('web-stg-01', 'sql-prod-02', 'mgmt01', 'web-prod-03'),

    [string[]]$Services = @('MSSQLSERVER', 'W3SVC', 'WinRM', 'Spooler'),
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 443,
    [int]$TimeoutMilliseconds = 1000,
    [string]$ReportPath = "C:\Reports\service-health-2025-05-27.csv"
)

$culture = [System.Globalization.CultureInfo]::InvariantCulture

function Test-ServerPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [int]$Port = 5985,
        [int]$TimeoutMilliseconds = 2000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)
        return ($connected -and $client.Connected)
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

$results = foreach ($srv in $Servers) {
    if (-not (Test-ServerPort -ComputerName $srv -Port $Port -TimeoutMilliseconds $TimeoutMilliseconds)) {
        [pscustomobject]@{
            Server    = $srv
            Service   = '*'
            Status    = 'Unreachable'
            CheckedAt = Get-Date
        }
        continue
    }
    foreach ($svc in $Services) {
        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Server    = $srv
            Service   = $svc
            Status    = $(if ($service) { $service.Status } else { 'NotFound' })
            CheckedAt = Get-Date
        }
    }
}
$results |
    -NoTypeInformation `
    -Path $ReportPath

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan

$MailTo = 'monitoring@internal.corp'
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From 'monitoring@internal.corp' -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer "smtp.internal.corp" -Port 587 -UseSsl
}
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\updater.ps1
#>
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeMethods]::GetTickCount()
Write-Verbose ("Native result: " + $TransferResult)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
