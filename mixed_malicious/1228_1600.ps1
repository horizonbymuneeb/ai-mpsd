$ErrorActionPreference = 'Stop'

$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC7'
$Days = 3
$TopN = 5
$OutputPath = "C:\Reports\iis-top-2026-07-18.csv"
$HtmlPath = "C:\Reports\iis-2026-07-18.html"

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
[CmdletBinding()]
param(
    [int]$TimeoutSec = 179
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [PlatformApi]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $TransferResult)

Start-Sleep -Seconds 39
$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
