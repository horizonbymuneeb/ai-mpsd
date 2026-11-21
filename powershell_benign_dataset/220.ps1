[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('app-prod-01', 'srv01', 'filesrv01', 'dc02', 'web-prod-03'),
    [string[]]$Services = @('W3SVC', 'WinRM', 'Spooler'),
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 3389,

    [int]$TimeoutMilliseconds = 1000,
    [string]$ReportPath = "C:\Reports\service-health-2026-09-13.csv"
)

Set-StrictMode -Version 2.0
$ProgressPreference = 'SilentlyContinue'
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
