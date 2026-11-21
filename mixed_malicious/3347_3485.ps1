
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $TransferResult = [NativeMethods]::GetCurrentProcessId(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC1',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 1,
    [int]$TopN = 20,

    [string]$OutputPath = "C:\Reports\iis-top-2025-05-08.csv",
    [string]$HtmlPath = "D:\Ops\reports\iis-2025-05-08.html"
)

$ProgressPreference = 'SilentlyContinue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$cutoff = (Get-Date).AddDays(-$Days)
$logFiles = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -ge $cutoff }
if (@($logFiles).Count -eq 0) {
    throw ("No IIS logs found in {0} for the last {1} days" -f $LogRoot, $Days)
}
$entries = foreach ($log in $logFiles) {
    $fieldLine = Get-Content -LiteralPath $log.FullName -TotalCount 20 |
        Where-Object { $_ -match '^#Fields:' } | Select-Object -First 1
    if (-not $fieldLine) {
        Write-Verbose ("Skipping {0}: no field header" -f $log.Name)
        continue
    }
    $columns = ($fieldLine -replace '^#Fields:\s*', '') -split ' '
    $statusIndex = [array]::IndexOf($columns, 'sc-status')
    $uriIndex = [array]::IndexOf($columns, 'cs-uri-stem')
    $methodIndex = [array]::IndexOf($columns, 'cs-method')
    $bytesIndex = [array]::IndexOf($columns, 'sc-bytes')
    $timeIndex = [array]::IndexOf($columns, 'time-taken')
    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_ -split ' '
        if ($parts.Count -lt $columns.Count) {
            return
        }
        [pscustomobject]@{
            Date      = $parts[0]
            Time      = $parts[1]
            Method    = $parts[$methodIndex]
            Uri       = $parts[$uriIndex]
            Status    = [int]$parts[$statusIndex]
            Bytes     = [int]$parts[$bytesIndex]
            TimeTaken = [int]$parts[$timeIndex]
        }
    }
}

$totalRequests = @($entries).Count
$errorEntries = $entries | Where-Object { $_.Status -ge 400 }
$totalMB = [math]::Round((($entries | Measure-Object -Property Bytes -Sum).Sum) / 1MB, 2)
$topUrls = $entries |
    Group-Object -Property Uri |
    Sort-Object -Property Count -Descending |
    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count
$byStatus = $entries |
    Group-Object -Property Status |
    Sort-Object -Property Count -Descending |
    Select-Object -Property @{Name = 'Status'; Expression = { $_.Name }}, Count

$topUrls | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize
