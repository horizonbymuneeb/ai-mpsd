
$ErrorActionPreference = 'Stop'
$Domain         = "internal.corp"
$SearchBase     = "OU=Contractors,DC=internal,DC=corp"
$ReportPath     = 'C:\Logs\reports\ad-user-audit-2024-11-13.csv'
$HtmlPath       = 'C:\Logs\reports\ad-user-audit-2024-11-13.html'
$InactiveDays   = 45
$PasswordMaxAge = 120
$SmtpServer     = "smtp.internal.corp"
$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'

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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -NoTypeInformation -Path $ReportPath.Replace('.csv', '-passwords.csv')

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
    -Port 2525 `
    -UseSsl
