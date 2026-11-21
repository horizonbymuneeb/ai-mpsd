
$Domain = 'adatum.com'
$SearchBase = 'OU=Users,DC=adatum,DC=com'
$ReportPath = "C:\Reports\ad-user-audit-2024-06-24.csv"
$InactiveDays = 90


Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate |
    -Path $ReportPath `
    -NoTypeInformation

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
