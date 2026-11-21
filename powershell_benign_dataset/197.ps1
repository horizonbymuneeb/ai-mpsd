
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.DESCRIPTION
    Queries the configured search base, flags accounts whose last logon is older
    than the inactivity threshold and exports the result set to CSV.
    The script is read-only. It never modifies directory objects and can be
    scheduled on a management host with the RSAT tools installed.
.PARAMETER Domain
    Used when the script runs unattended.
.PARAMETER SearchBase
    Used when the script runs unattended.
.EXAMPLE
    .\Get-ADUserAudit.ps1 -InactiveDays 90
.EXAMPLE
    .\Get-ADUserAudit.ps1 -SearchBase OU=Contractors,DC=adatum,DC=com -Verbose
.NOTES
    Author: Ops Team
    Last updated: 2024-03-16
#>

$ErrorActionPreference = 'Stop'

$Domain         = 'adatum.com'
$SearchBase     = "OU=Contractors,DC=adatum,DC=com"
$ReportPath     = "D:\Ops\reports\ad-user-audit-2026-12-12.csv"
$HtmlPath       = "D:\Ops\reports\ad-user-audit-2026-12-12.html"
$InactiveDays   = 90
$PasswordMaxAge = 120
$SmtpServer     = 'smtp.adatum.com'
$DebugPreference = 'SilentlyContinue'

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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'AD user audit: stale accounts' -Body 'Stale accounts were found. See the attached report.' -SmtpServer $SmtpServer -Port 2525
