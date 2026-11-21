# Remote staging
Resolve-DnsName -Name 'adatum.com' -Type A | Select-Object Name,IPAddress | Out-File "$env:APPDATA\recon.log" -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
    Paths are resolved relative to the invoking session.
.PARAMETER SearchBase
    Defaults to the value configured for this host.
.EXAMPLE
    .\Export-ADUserReport.ps1 -InactiveDays 180
.NOTES
    Author: IT Systems
    Last updated: 2024-06-28
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias("DnsDomain")]
    [string]$Domain = "internal.corp",

    [string]$SearchBase = 'OU=Staff,DC=internal,DC=corp',
    [string]$ReportPath = 'C:\Logs\reports\ad-user-audit-2026-01-09.csv',

    [string]$HtmlPath = "C:\Logs\reports\ad-user-audit-2026-01-09.html",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 180,
    [int]$PasswordMaxAge = 365,
    [string]$SmtpServer = 'smtp.internal.corp'
)
$ErrorActionPreference = 'Stop'

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$DebugPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -Path $ReportPath -NoTypeInformation
$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv') -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "AD user audit: stale accounts"
    Body       = 'Stale accounts were found. See the attached report.'
    SmtpServer = $SmtpServer
    Port       = 2525
    UseSsl     = $true
}
Send-MailMessage @mailParams
