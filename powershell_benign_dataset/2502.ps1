
<#
.SYNOPSIS
    Checks the configured Windows services on a list of servers.
.DESCRIPTION
    Probes the management port first, then queries each service and records the
    state in a result set that is exported to CSV.
    Any service that is not Running triggers a single alert mail with the
    offending rows.
.PARAMETER Servers
    Paths are resolved relative to the invoking session.
.PARAMETER Services
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Test-ServiceHealth.ps1 -Servers app-prod-01, dc01
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string[]]$Servers = @('app-prod-01', 'dc01', 'web-stg-01'),

    [string[]]$Services = @('DNS', 'Spooler', 'WinRM'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 5986,
    [int]$TimeoutMilliseconds = 5000,

    [string]$ReportPath = 'C:\Reports\service-health-2024-10-08.csv'
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
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
    -Path $ReportPath `
    -Encoding UTF8

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan

$MailTo = 'monitoring@internal.corp'
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From 'monitoring@internal.corp' -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer "smtp.internal.corp" -Port 25 -UseSsl
}
