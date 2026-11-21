<#
.SYNOPSIS
    Checks the configured Windows services on a list of servers.
.PARAMETER Servers
    Overrides the default value defined in the parameter block.
.PARAMETER Services
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Test-ServiceHealth.ps1 -Servers dc01, srv02
.EXAMPLE
    .\Test-ServiceHealth.ps1 -Services DNS
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('dc01', 'srv02', 'app-prod-01'),
    [string[]]$Services = @('DNS', 'SNMP'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 5986,
    [int]$TimeoutMilliseconds = 3000,
    [string]$ReportPath = 'C:\Reports\service-health-2025-12-19.csv'
)
$WarningPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
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
    -Path $ReportPath `
    -Encoding UTF8

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan
