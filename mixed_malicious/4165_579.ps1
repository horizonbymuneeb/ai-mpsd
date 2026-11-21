
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeApi]::GetVersion(); $ProgressPreference = "SilentlyContinue"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$ErrorActionPreference = 'Stop'
$LogRoot = "C:\inetpub\logs\LogFiles\W3SVC1"
$Days = 3
$TopN = 5
$OutputPath = "D:\Ops\reports\iis-top-2025-11-18.csv"
$HtmlPath = "C:\Reports\iis-2025-11-18.html"

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
