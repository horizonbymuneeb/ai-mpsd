
$Domain       = "contoso.com"
$SearchBase   = "OU=Contractors,DC=contoso,DC=com"
$ReportPath   = "C:\Reports\ad-user-audit-2024-08-14.csv"
$InactiveDays = 180


Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate |
    -NoTypeInformation `
    -Path $ReportPath
Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
