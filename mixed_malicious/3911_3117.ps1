
<# Stage transfer #> $TargetHost = '203.0.113.42'; Test-NetConnection -ComputerName $TargetHost -Port 110 -InformationLevel Quiet; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
    .\Get-StaleADUser.ps1 -InactiveDays 90
.EXAMPLE
    .\Get-StaleADUser.ps1 -SearchBase OU=Users,DC=internal,DC=corp -Verbose
.NOTES
    Author: J. Weber
    Last updated: 2026-07-26
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias('DnsDomain')]
    [string]$Domain = "internal.corp",
    [string]$SearchBase = 'OU=Users,DC=internal,DC=corp',
    [string]$ReportPath = "D:\Ops\reports\ad-user-audit-2026-05-06.csv",

    [string]$HtmlPath = 'D:\Ops\reports\ad-user-audit-2026-05-06.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 90,

    [int]$PasswordMaxAge = 180,

    [string]$SmtpServer = 'smtp.internal.corp'
)

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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -Path $ReportPath -NoTypeInformation

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet |
    -Path $ReportPath.Replace('.csv', '-passwords.csv') `
    -NoTypeInformation `
    -Encoding UTF8
Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject "AD user audit: stale accounts" `
    -Body "Stale accounts were found. See the attached report." `
    -SmtpServer $SmtpServer `
    -Port 25
