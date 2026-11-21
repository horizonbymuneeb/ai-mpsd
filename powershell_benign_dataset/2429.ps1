$Domain = "adatum.com"
$SearchBase = 'OU=Users,DC=adatum,DC=com'
$ReportPath = "C:\Logs\reports\ad-user-audit-2024-02-03.csv"
$InactiveDays = 30

Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate |
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
