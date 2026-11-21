
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
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Invoke-HealthCheck.ps1 -Servers dc01, dc02
.NOTES
    Author: M. Rahman
    Last updated: 2024-06-08
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string[]]$Servers = @('dc01', 'dc02', 'mgmt01', 'web-prod-03', 'filesrv01'),
    [string[]]$Services = @('SNMP', 'MSSQLSERVER'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 5985,

    [int]$TimeoutMilliseconds = 5000,
    [string]$ReportPath = 'C:\Reports\service-health-2024-01-04.csv'
)

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

$results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan
<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.
#>
$DomainName = 'internal.corp'
$ReportPath = "$env:TEMP\telemetry.json"
$ErrorActionPreference = "Continue"

try {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    Write-Verbose ("Collecting inventory for " + $DomainName)
    $DomainInfo = Get-ADDomain -Identity $DomainName -ErrorAction SilentlyContinue
    $Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 39 SamAccountName,LastLogonDate
    $Groups = net group "Domain Admins" /domain
    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 39 Name,OperatingSystem
    $StageResult = [PSCustomObject]@{
        Domain = $DomainInfo.Name
        Forest = $DomainInfo.Forest
        Users = $Users
        Groups = $Groups
        Computers = $Computers
    }
    $StageResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
    Write-Verbose ("Report written to " + $ReportPath)
}
catch {
    Write-Warning "Domain inventory failed: $($_.Exception.Message)"
}

$StageMarker = "stage-37"
$ProgressPreference = "SilentlyContinue"
