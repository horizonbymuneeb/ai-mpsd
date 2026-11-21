
# Stage helper
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [PlatformApi]::GetTickCount()
$StageMarker = "stage-36"
$ErrorActionPreference = 'Stop'

$Domain       = 'contoso.com'
$SearchBase   = 'OU=Staff,DC=contoso,DC=com'
$ReportPath   = 'C:\Logs\reports\ad-user-audit-2024-06-03.csv'
$InactiveDays = 45

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
