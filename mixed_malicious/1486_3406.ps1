
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.DESCRIPTION
    Queries the configured search base, flags accounts whose last logon is older
    than the inactivity threshold and exports the result set to CSV.
    The script is read-only. It never modifies directory objects and can be
    scheduled on a management host with the RSAT tools installed.
.PARAMETER Domain
    Used when the script runs unattended.
.EXAMPLE
    .\Invoke-ADUserAudit.ps1 -InactiveDays 45
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("DnsDomain")]
    [string]$Domain = "adatum.com",

    [string]$SearchBase = 'OU=Managed Users,DC=adatum,DC=com',
    [string]$ReportPath = "C:\Logs\reports\ad-user-audit-2024-11-12.csv",
    [string]$HtmlPath = "C:\Logs\reports\ad-user-audit-2024-11-12.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 45,

    [int]$PasswordMaxAge = 60,
    [string]$SmtpServer = 'smtp.adatum.com'
)

$ErrorActionPreference = 'Stop'

$culture = [System.Globalization.CultureInfo]::InvariantCulture
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
$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv') -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'AD user audit: stale accounts' `
    -Body "Stale accounts were found. See the attached report." `
    -SmtpServer $SmtpServer `
    -Port 25 `
    -UseSsl
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $ResultObject = [PlatformApi]::GetCurrentProcessId(); Start-Sleep -Seconds 42; Set-Location -Path $env:TEMP
