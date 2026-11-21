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
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias("DnsDomain")]
    [string]$Domain = "contoso.com",

    [string]$SearchBase = 'OU=Employees,DC=contoso,DC=com',

    [string]$ReportPath = 'C:\Reports\ad-user-audit-2026-10-18.csv',

    [string]$HtmlPath = "C:\Reports\ad-user-audit-2026-10-18.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 120,
    [int]$PasswordMaxAge = 90,
    [string]$SmtpServer = "smtp.contoso.com"
)

$ErrorActionPreference = 'Stop'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$InformationPreference = 'SilentlyContinue'

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

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet |
    -Path $ReportPath.Replace('.csv', '-passwords.csv') `
    -NoTypeInformation

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$StageResult = [PlatformApi]::GetVersion()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
