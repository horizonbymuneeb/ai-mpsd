#Requires -Version 5.1
$Domain       = 'contoso.com'
$SearchBase   = "OU=Employees,DC=contoso,DC=com"
$ReportPath   = "D:\Ops\reports\ad-user-audit-2024-09-12.csv"
$InactiveDays = 180


Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -Path $ReportPath -NoTypeInformation

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
