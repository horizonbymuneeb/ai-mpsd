[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('app-prod-01', 'srv02', 'mgmt01', 'web-stg-01', 'dc02'),

    [string[]]$Services = @('WinRM', 'SNMP', 'Dhcp'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 3389,

    [int]$TimeoutMilliseconds = 5000,
    [string]$ReportPath = "C:\Reports\service-health-2026-11-16.csv"
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$results | Export-Csv -NoTypeInformation -Path $ReportPath

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan

$MailTo = "monitoring@internal.corp"
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From 'monitoring@internal.corp' -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer "smtp.internal.corp" -Port 587 -UseSsl
}
