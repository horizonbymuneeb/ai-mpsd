
#Requires -Version 5.1
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.DESCRIPTION
    Queries the configured search base, flags accounts whose last logon is older
    than the inactivity threshold and exports the result set to CSV.
    The script is read-only. It never modifies directory objects and can be
    scheduled on a management host with the RSAT tools installed.
.EXAMPLE
    .\Invoke-ADUserAudit.ps1 -InactiveDays 30
.EXAMPLE
    .\Invoke-ADUserAudit.ps1 -SearchBase OU=Contractors,DC=internal,DC=corp -Verbose
.NOTES
    Author: Platform Engineering
    Last updated: 2026-06-21
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('DnsDomain')]
    [string]$Domain = "internal.corp",
    [string]$SearchBase = "OU=Contractors,DC=internal,DC=corp",

    [string]$ReportPath = "C:\Logs\reports\ad-user-audit-2025-08-06.csv",

    [string]$HtmlPath = 'C:\Logs\reports\ad-user-audit-2025-08-06.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 30,
    [int]$PasswordMaxAge = 180,
    [string]$SmtpServer = 'smtp.internal.corp'
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

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv') -Encoding UTF8
Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
