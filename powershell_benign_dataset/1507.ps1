#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('DnsDomain')]
    [string]$Domain = 'internal.corp',

    [string]$SearchBase = 'OU=Staff,DC=internal,DC=corp',
    [string]$ReportPath = "C:\Reports\ad-user-audit-2024-08-11.csv",
    [string]$HtmlPath = "C:\Reports\ad-user-audit-2024-08-11.html",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 180,
    [int]$PasswordMaxAge = 60,

    [string]$SmtpServer = "smtp.internal.corp"
)
$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$WarningPreference = 'Continue'

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
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv') -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
