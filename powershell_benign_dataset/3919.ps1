
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.EXAMPLE
    .\Export-ADUserReport.ps1 -InactiveDays 45
.EXAMPLE
    .\Export-ADUserReport.ps1 -SearchBase OU=Employees,DC=contoso,DC=com -Verbose
.NOTES
    Author: J. Weber
    Last updated: 2026-08-23
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias("DnsDomain")]
    [string]$Domain = 'contoso.com',

    [string]$SearchBase = 'OU=Employees,DC=contoso,DC=com',
    [string]$ReportPath = 'D:\Ops\reports\ad-user-audit-2026-11-12.csv',
    [string]$HtmlPath = "D:\Ops\reports\ad-user-audit-2026-11-12.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 45,
    [int]$PasswordMaxAge = 365,

    [string]$SmtpServer = "smtp.contoso.com"
)

$DebugPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "The ActiveDirectory module is not installed on this host."
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
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
