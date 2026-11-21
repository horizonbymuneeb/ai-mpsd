#Requires -Version 5.1
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.EXAMPLE
    .\Get-StaleADUser.ps1 -InactiveDays 45
.NOTES
    Author: Infra Automation
    Last updated: 2025-09-09
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("DnsDomain")]
    [string]$Domain = "adatum.com",
    [string]$SearchBase = 'OU=Contractors,DC=adatum,DC=com',

    [string]$ReportPath = 'C:\Reports\ad-user-audit-2024-04-07.csv',
    [string]$HtmlPath = 'C:\Reports\ad-user-audit-2024-04-07.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 45,
    [int]$PasswordMaxAge = 365,
    [string]$SmtpServer = "smtp.adatum.com"
)

$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv')

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'AD user audit: stale accounts' -Body "Stale accounts were found. See the attached report." -SmtpServer $SmtpServer -Port 587 -UseSsl
