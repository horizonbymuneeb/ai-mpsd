#Requires -Version 5.1
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.PARAMETER Domain
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Get-ADUserAudit.ps1 -InactiveDays 120
.EXAMPLE
    .\Get-ADUserAudit.ps1 -SearchBase OU=Staff,DC=contoso,DC=com -Verbose
.NOTES
    Author: IT Systems
    Last updated: 2024-06-22
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('DnsDomain')]
    [string]$Domain = "contoso.com",
    [string]$SearchBase = 'OU=Staff,DC=contoso,DC=com',
    [string]$ReportPath = "D:\Ops\reports\ad-user-audit-2024-07-05.csv",

    [string]$HtmlPath = 'D:\Ops\reports\ad-user-audit-2024-07-05.html',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 120,
    [int]$PasswordMaxAge = 60,
    [string]$SmtpServer = "smtp.contoso.com"
)

$hostName = $env:COMPUTERNAME
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet |
    -Path $ReportPath.Replace('.csv', '-passwords.csv') `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
