
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("DnsDomain")]
    [string]$Domain = 'contoso.com',
    [string]$SearchBase = 'OU=Staff,DC=contoso,DC=com',

    [string]$ReportPath = "C:\Logs\reports\ad-user-audit-2025-08-14.csv",

    [string]$HtmlPath = "C:\Logs\reports\ad-user-audit-2025-08-14.html",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 30,

    [int]$PasswordMaxAge = 60,
    [string]$SmtpServer = 'smtp.contoso.com'
)

$ErrorActionPreference = 'Stop'
$hostName = $env:COMPUTERNAME
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$DebugPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

$LogPath = 'C:\Logs\ad-audit-2025-08-14.log'

function Write-AuditLog {
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
    "OU=Staff,DC=contoso,DC=com"
    "OU=ServiceAccounts,DC=contoso,DC=com"
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

$groupReport | Export-Csv -Path "C:\Logs\reports\ad-user-audit-2025-08-14-groups.csv" -NoTypeInformation -Encoding UTF8

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled |
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8
$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet |
    -NoTypeInformation `
    -Path $ReportPath.Replace('.csv', '-passwords.csv')

$disabled = $users | Where-Object { $_.Enabled -eq $false }
$disabled | Select-Object Name, SamAccountName, DistinguishedName |
    Export-Csv -Path $ReportPath.Replace('.csv', '-disabled.csv') -NoTypeInformation -Encoding UTF8

$style = @'
<style>
body { font-family: Arial; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
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

Send-MailMessage -To $MailTo -From $MailFrom -Subject "AD user audit: daily summary" -Body $summaryBody -SmtpServer $SmtpServer -Port 2525 -UseSsl

Write-Host ("AD audit finished: {0} stale, {1} disabled" -f $staleCount, $disabledCount) -ForegroundColor Green
Write-AuditLog -Message ("Audit completed for {0}" -f $Domain) -Level INFO

$byOu = $users | Group-Object -Property DistinguishedName |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byOu | Format-Table -AutoSize | Out-String | Write-Verbose

$sampleStale = $stale | Sort-Object -Property LastLogonDate | Select-Object -First 10
$sampleStale | Format-Table Name, SamAccountName, LastLogonDate -AutoSize

$neverLoggedOn = $users | Where-Object { $_.LastLogonDate -eq $null }
if (@($neverLoggedOn).Count -gt 0) {
    Write-Warning ("{0} accounts have never signed in" -f @($neverLoggedOn).Count)
}

$transcript = Join-Path $env:TEMP ("ad-audit-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null
Write-Verbose ("Transcript: {0}" -f $transcript)

$ous = Get-ADOrganizationalUnit -Filter * -ErrorAction SilentlyContinue |
    Select-Object -First 5 -Property Name, DistinguishedName
$ous | Format-Table -AutoSize

$reportItem = Get-Item -LiteralPath $ReportPath -ErrorAction SilentlyContinue
if ($reportItem) {
    Write-Host ("Report size: {0:N1} KB" -f ($reportItem.Length / 1KB)) -ForegroundColor Gray
}

$engine = Get-ADRootDSE -ErrorAction SilentlyContinue
if ($engine) {
    Write-Verbose ("Domain controller: {0}" -f $engine.dnsHostName)
    Write-Verbose ("Default naming context: {0}" -f $engine.defaultNamingContext)
}

$pwdPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
if ($pwdPolicy) {
    Write-Verbose ("Domain password age: {0} days" -f $pwdPolicy.MaxPasswordAge.Days)
}

$expiringSoon = $users | Where-Object {
    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt (Get-Date).AddDays(-($PasswordMaxAge - 14))
}
Write-Verbose ("Password changes due: {0}" -f @($expiringSoon).Count)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
