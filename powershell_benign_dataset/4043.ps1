#Requires -Version 5.1
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.DESCRIPTION
    Queries the configured search base, flags accounts whose last logon is older
    than the inactivity threshold and exports the result set to CSV.
    The script is read-only. It never modifies directory objects and can be
    scheduled on a management host with the RSAT tools installed.
.PARAMETER Domain
    Overrides the default value defined in the parameter block.
.PARAMETER SearchBase
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Get-ADUserAudit.ps1 -InactiveDays 90
.NOTES
    Author: IT Systems
    Last updated: 2024-08-06
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias('DnsDomain')]
    [string]$Domain = 'contoso.com',
    [string]$SearchBase = 'OU=Contractors,DC=contoso,DC=com',
    [string]$ReportPath = 'C:\Reports\ad-user-audit-2026-07-20.csv',
    [string]$HtmlPath = "C:\Reports\ad-user-audit-2026-07-20.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 90,

    [int]$PasswordMaxAge = 90,
    [string]$SmtpServer = 'smtp.contoso.com'
)

Set-StrictMode -Version 2.0
$InformationPreference = 'SilentlyContinue'
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

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = 'AD user audit: stale accounts'
    Body       = 'Stale accounts were found. See the attached report.'
    SmtpServer = $SmtpServer
    Port       = 2525
    UseSsl     = $true
}
Send-MailMessage @mailParams
