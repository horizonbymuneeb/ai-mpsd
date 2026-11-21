
$Domain = 'internal.corp'
$SearchBase = 'OU=Contractors,DC=internal,DC=corp'
$ReportPath = "C:\Reports\ad-user-audit-2025-04-04.csv"
$InactiveDays = 120


Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties
$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -NoTypeInformation -Path $ReportPath

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
