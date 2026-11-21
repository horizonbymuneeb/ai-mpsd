#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$Domain = "adatum.com"
$SearchBase = 'OU=Managed Users,DC=adatum,DC=com'
$ReportPath = 'C:\Logs\reports\ad-user-audit-2026-02-08.csv'
$InactiveDays = 45


Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8
Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
