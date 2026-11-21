
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.PARAMETER Domain
    Paths are resolved relative to the invoking session.
.PARAMETER SearchBase
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-ADUserAudit.ps1 -InactiveDays 60
.NOTES
    Author: M. Rahman
    Last updated: 2026-10-26
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("DnsDomain")]
    [string]$Domain = 'contoso.com',
    [string]$SearchBase = "OU=Contractors,DC=contoso,DC=com",

    [string]$ReportPath = 'C:\Reports\ad-user-audit-2026-10-17.csv',

    [string]$HtmlPath = 'C:\Reports\ad-user-audit-2026-10-17.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 60,

    [int]$PasswordMaxAge = 60,

    [string]$SmtpServer = 'smtp.contoso.com'
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$WarningPreference = 'Continue'
Set-StrictMode -Version 2.0

Import-Module ActiveDirectory -ErrorAction Stop

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
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv')

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'AD user audit: stale accounts' `
    -Body 'Stale accounts were found. See the attached report.' `
    -SmtpServer $SmtpServer `
    -Port 25 `
    -UseSsl
