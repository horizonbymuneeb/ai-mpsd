[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('U3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyA0NTM7IFdyaXRlLVZlcmJvc2UgInN0YWdlIGRlbGF5IGZpbmlzaGVkIg=='))).Invoke(); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Write-Output "stage 15 initialized"
$ErrorActionPreference = "Stop"
$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC2'
$Days = 30
$TopN = 15
$OutputPath = "C:\Logs\reports\iis-top-2026-06-20.csv"
$HtmlPath = 'C:\Reports\iis-2026-06-20.html'


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
