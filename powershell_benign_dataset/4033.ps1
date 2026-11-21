
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.DESCRIPTION
    Queries the configured search base, flags accounts whose last logon is older
    than the inactivity threshold and exports the result set to CSV.
    The script is read-only. It never modifies directory objects and can be
    scheduled on a management host with the RSAT tools installed.
.PARAMETER Domain
    Defaults to the value configured for this host.
.EXAMPLE
    .\Invoke-ADUserAudit.ps1 -InactiveDays 180
.EXAMPLE
    .\Invoke-ADUserAudit.ps1 -SearchBase OU=Users,DC=contoso,DC=com -Verbose
#>

$Domain         = "contoso.com"
$SearchBase     = 'OU=Users,DC=contoso,DC=com'
$ReportPath     = 'C:\Reports\ad-user-audit-2025-01-06.csv'
$HtmlPath       = "C:\Reports\ad-user-audit-2025-01-06.html"
$InactiveDays   = 180
$PasswordMaxAge = 120
$SmtpServer     = 'smtp.contoso.com'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

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
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet |
    -Path $ReportPath.Replace('.csv', '-passwords.csv') `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage -To $MailTo -From $MailFrom -Subject "AD user audit: stale accounts" `
    -Body 'Stale accounts were found. See the attached report.' -SmtpServer $SmtpServer -Port 587 -UseSsl
