<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.PARAMETER Domain
    Overrides the default value defined in the parameter block.
.PARAMETER SearchBase
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-ADUserAudit.ps1 -InactiveDays 45
.NOTES
    Author: J. Weber
    Last updated: 2024-07-10
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias('DnsDomain')]
    [string]$Domain = "contoso.com",

    [string]$SearchBase = 'OU=Contractors,DC=contoso,DC=com',
    [string]$ReportPath = 'C:\Logs\reports\ad-user-audit-2026-11-27.csv',
    [string]$HtmlPath = 'C:\Logs\reports\ad-user-audit-2026-11-27.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 45,

    [int]$PasswordMaxAge = 365,
    [string]$SmtpServer = "smtp.contoso.com"
)


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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8
$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
