
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$Domain = "internal.corp"
$SearchBase = "OU=Employees,DC=internal,DC=corp"
$ReportPath = 'C:\Reports\ad-user-audit-2025-11-27.csv'
$InactiveDays = 90


Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate |
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
